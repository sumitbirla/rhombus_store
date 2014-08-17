require 'securerandom'


class Admin::Shipping::StampsController < Admin::BaseController

  def client
    @client ||= Savon.client :wsdl => Rails.root.join('wsdl', 'swsimv35.wsdl'),
                             :pretty_print_xml => true,
                             :convert_request_keys_to => :camelcase
  end

  def get_auth
    response = client.call(:authenticate_user, message: {
        credentials: {
            "IntegrationID" => Cache.setting('Shipping', 'Stamps.com Integration ID'),
            :username => Cache.setting('Shipping', 'Stamps.com Username'),
            :password => Cache.setting('Shipping', 'Stamps.com Password')
        }
    })
    response.body[:authenticate_user_response][:authenticator]
  end

  def index
    @shipment = Shipment.find(params[:shipment_id])
    @shipment.ship_date = Date.today
    @shipment.packaging_type = 'Package'
  end

  def rates
    @shipment = Shipment.find(params[:shipment_id])
    @shipment.assign_attributes(shipment_params)

    @shipment.errors.add(:packaging_type, 'must be specified') if @shipment.packaging_type.blank?
    @shipment.errors.add(:package_weight, 'must be specified') if @shipment.package_weight.blank?
    @shipment.errors.add(:ship_date, 'must be specified') if @shipment.ship_date.blank?
    return render 'index' if @shipment.errors.count > 0

    begin
      # get AUTHENTICATOR first
      auth = get_auth

      # cleanse SHIP_FROM address
      response = client.call(:cleanse_address, message: {
          authenticator: auth,
          address: {
              full_name: @shipment.ship_from_company,
              address1: @shipment.ship_from_street1,
              address2: @shipment.ship_from_street2 || '',
              city: @shipment.ship_from_city,
              state: @shipment.ship_from_state,
              "ZIPCode" => @shipment.ship_from_zip.split('-')[0]
          }
      })

      data = response.body[:cleanse_address_response]
      @ship_from_address = data[:address]
      auth = data[:authenticator]

      # cleanse RECIPIENT addresses
      response = client.call(:cleanse_address, message: {
          authenticator: auth,
          address: {
              full_name: @shipment.recipient_name,
              company: @shipment.recipient_company || '',
              address1: @shipment.recipient_street1,
              address2: @shipment.recipient_street2 || '',
              city: @shipment.recipient_city,
              state: @shipment.recipient_state,
              "ZIPCode" => @shipment.recipient_zip.split('-')[0]
          }
      })

      data = response.body[:cleanse_address_response]
      @recipient_address = data[:address]
      auth = data[:authenticator]

      # get RATES
      response = client.call(:get_rates, message: {
          authenticator: auth,
          rate: {
              "FromZIPCode" => @shipment.ship_from_zip,
              "ToZIPCode" => @shipment.recipient_zip,
              :weight_lb => @shipment.package_weight,
              :package_type => @shipment.packaging_type,
              :ship_date => @shipment.ship_date.strftime("%Y-%m-%d")
          }
      })

      @rates = response.body[:get_rates_response][:rates][:rate]
      Rails.cache.write("#{@shipment.id}-rates", @rates, expires_in: 30.minutes)
      Rails.cache.write("#{@shipment.id}-ship-from", @ship_from_address)
      Rails.cache.write("#{@shipment.id}-recipient", @recipient_address)

    rescue Exception => e
      flash[:error] = e.message
      Rails.logger.error e
    end

    render 'index'
  end


  def label

    @shipment = Shipment.find(params[:shipment_id])
    from = Rails.cache.read("#{@shipment.id}-ship-from")
    to = Rails.cache.read("#{@shipment.id}-recipient")
    rates = Rails.cache.read("#{@shipment.id}-rates")


    begin
      # find chosen rate
      rate = rates.find { |r| r[:service_type] == params[:service_type] }
      if rate.nil?
        @shipments.errors.add(:base, "Selected rate not found.  Please try again.")
        return render 'index'
      end

      #return render json: rate

      # select addons
      addons = []
      total_cost = rate[:amount].to_f

      unless params[:addons].nil?
        rate[:add_ons][:add_on_v5].each do |a|
          if params[:addons].include?(a[:add_on_type])
            addons << {
                :amount => a[:amount],
                :add_on_type => a[:add_on_type]
            }
            total_cost += a[:amount].to_f
          end
        end
      end

      from_address = {
          :full_name => from[:full_name],
          :address1 => from[:address1],
          :city => from[:city],
          :state => from[:state],
          "ZIPCode" => from[:zip_code],
          "ZIPCodeAddOn" => from[:zip_code_add_on],
          :cleanse_hash => from[:cleanse_hash]
      }
      from_address[:address2] = from[:address2] unless from[:address2].nil?

      to_address =  {
          :full_name => to[:full_name],
          :address1 => to[:address1],
          :city => to[:city],
          :State => to[:state],
          "ZIPCode" => to[:zip_code],
          "ZIPCodeAddOn" => to[:zip_code_add_on],
          :cleanse_hash => to[:cleanse_hash]
      }
      to_address[:company] = to[:company] unless to[:company].nil?
      to_address[:address2] = to[:address2] unless to[:address2].nil?

      req = {
          authenticator: get_auth,
          "IntegratorTxID" => SecureRandom.uuid,
          rate: {
            "FromZIPCode" => rate[:from_zip_code],
            "ToZIPCode" => rate[:to_zip_code],
            :service_type => rate[:service_type],
            :weight_lb => rate[:weight_lb],
            :package_type => rate[:package_type],
            :ship_date => rate[:ship_date],
            :add_ons => {
                :add_on_v5 => addons
            }
          },
          from: from_address,
          to: to_address,
          sample_only: true,
          image_type: params[:format],
          "memo" => @shipment.to_s,
          return_image_data: true
      }

      req.delete(:sample_only) if Cache.setting("Shipping", "Stamps.com Mode") != "test"


      #return render json: req

      response = client.call(:create_indicium, message: req)
      data = response.body[:create_indicium_response]

      @shipment.status = "shipped"
      @shipment.packaging_type = rate[:package_type]
      @shipment.package_weight = rate[:weight_lb]
      @shipment.ship_date = rate[:ship_date]
      @shipment.ship_method = rate[:service_type]
      @shipment.ship_cost = total_cost
      @shipment.tracking_number = data[:tracking_number]
      @shipment.label_format = params[:format].upcase
      @shipment.label_data = Base64.decode64(data[:image_data][:base64_binary])

      @shipment.ship_from_company = from[:full_name]
      @shipment.ship_from_street1 = from[:address1]
      @shipment.ship_from_street2 = from[:address2]
      @shipment.ship_from_city = from[:city]
      @shipment.ship_from_state = from[:state]
      @shipment.ship_from_zip = from[:zip_code]
      @shipment.ship_from_zip += "-" + from[:zip_code_add_on] unless from[:zip_code_add_on].nil?

      @shipment.recipient_name = to[:full_name]
      @shipment.recipient_company = to[:company]
      @shipment.recipient_street1 = to[:address1]
      @shipment.recipient_street2 = to[:address2]
      @shipment.recipient_city = to[:city]
      @shipment.recipient_state = to[:state]
      @shipment.recipient_zip = to[:zip_code]
      @shipment.recipient_zip += "-" + to[:zip_code_add_on] unless to[:zip_code_add_on].nil?

      data.delete(:authenticator)
      data.delete(:image_data)
      @shipment.courier_data = data.to_json
      @shipment.save

      OrderHistory.create order_id: @shipment.order_id,
                          user_id: current_user.id,
                          event_type: 'package_shipped',
                          amount: total_cost,
                          system_name: 'stamps',
                          identifier: @shipment.tracking_number,
                          comment:  params[:service_type]

      @shipment.order.update_attribute(:status, 'shipped')

    rescue Exception => e
      flash[:error] = e.message
      Rails.logger.error e
      puts e
      return redirect_to :back
    end

    Rails.cache.delete("#{@shipment.id}-ship-from")
    Rails.cache.delete("#{@shipment.id}-recipient")
    Rails.cache.delete("#{@shipment.id}-rates")

    redirect_to admin_store_shipment_path(@shipment)

  end


  def void
    begin
      shipment = Shipment.find(params[:shipment_id])
      json = JSON.parse(shipment.courier_data)

      puts json.inspect

      client.call(:cancel_indicium, message: {
        authenticator: get_auth,
        "StampsTxID" => json["stamps_tx_id"]
      })

      flash[:info] = "Shipment has been voided."

      shipment.status = "void"
      shipment.save
    rescue Exception => e
      flash[:error] = e.message
      Rails.logger.error e
    end

    redirect_to :back
  end


  private

  def shipment_params
    params.require(:shipment).permit(:ship_date, :package_weight, :package_length, :package_width, :package_height, :packaging_type)
  end

end
