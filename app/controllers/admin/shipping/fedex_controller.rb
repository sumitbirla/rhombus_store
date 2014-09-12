class Admin::Shipping::FedexController < Admin::BaseController

  def index
    @shipment = Shipment.find(params[:shipment_id])
  end

  def rates
    @shipment = Shipment.find(params[:shipment_id])
    @shipment.assign_attributes(shipment_params)

    @shipment.errors.add(:packaging_type, 'must be specified') if @shipment.packaging_type.blank?
    @shipment.errors.add(:package_weight, 'must be specified') if @shipment.package_weight.blank?
    @shipment.errors.add(:drop_off_type, 'must be specified') if @shipment.drop_off_type.blank?
    return render 'index' if @shipment.errors.count > 0


    fedex = Fedex::Shipment.new(:key => Cache.setting('Shipping', 'Fedex API Key'),
                                :password => Cache.setting('Shipping', 'Fedex API Password'),
                                :account_number => Cache.setting('Shipping', 'Fedex Account Number'),
                                :meter => Cache.setting('Shipping', 'Fedex Meter Number'),
                                :mode => Cache.setting('Shipping', 'Fedex Mode'))

    shipper = { :name => @shipment.ship_from_company,
                :address => @shipment.ship_from_street1,
                :city => @shipment.ship_from_city,
                :state => @shipment.ship_from_state,
                :postal_code => @shipment.ship_from_zip,
                :country_code => Country.find_country_by_name(@shipment.ship_from_country).alpha2 }

    recipient = { :name => @shipment.recipient_name,
                  :company => @shipment.recipient_company,
                  :phone_number => @shipment.order.contact_phone,
                  :address => @shipment.recipient_street1,
                  :city => @shipment.recipient_city,
                  :state => @shipment.recipient_state,
                  :postal_code => @shipment.recipient_zip,
                  :country_code => @shipment.recipient_country,
                  :residential => "true" }

    package = {}
    package[:weight] = {:units => "LB", :value => @shipment.package_weight.ceil}
    package[:dimensions] = {:length => @shipment.package_length,
                            :width => @shipment.package_width,
                            :height => @shipment.package_height,
                            :units => "IN" }  if @shipment.dimensions_available?

    @shipping_details = {
        :packaging_type => @shipment.packaging_type,
        :drop_off_type => @shipment.drop_off_type
    }

    begin
      @rates, @response = fedex.rate(:shipper => shipper,
                                     :recipient => recipient,
                                     :packages => [ package ],
                                     :shipping_details => @shipping_details)
    rescue Exception => e
      flash[:error] = e.message
      puts e.inspect
    end

    render 'index'
  end


  def label
    @shipment = Shipment.find(params[:shipment_id])

    fedex = Fedex::Shipment.new(:key => Cache.setting('Shipping', 'Fedex API Key'),
                                :password => Cache.setting('Shipping', 'Fedex API Password'),
                                :account_number => Cache.setting('Shipping', 'Fedex Account Number'),
                                :meter => Cache.setting('Shipping', 'Fedex Meter Number'),
                                :mode => Cache.setting('Shipping', 'Fedex Mode'))

    shipper = { :name => @shipment.ship_from_company,
                :phone_number => "(813) 263-5178",
                :address => @shipment.ship_from_street1,
                :city => @shipment.ship_from_city,
                :state => @shipment.ship_from_state,
                :postal_code => @shipment.ship_from_zip,
                :country_code => Country.find_country_by_name(@shipment.ship_from_country).alpha2 }

    recipient = { :name => @shipment.recipient_name,
                  :company => @shipment.recipient_company,
                  :phone_number => @shipment.order.contact_phone,
                  :address => @shipment.recipient_street1,
                  :city => @shipment.recipient_city,
                  :state => @shipment.recipient_state,
                  :postal_code => @shipment.recipient_zip,
                  :country_code => Country.find_country_by_name(@shipment.recipient_country).alpha2,
                  :residential => "true" }

    shipping_details = {
        :packaging_type => @shipment.packaging_type,
        :drop_off_type => @shipment.drop_off_type
    }

    package = {}
    package[:weight] = {:units => "LB", :value => @shipment.package_weight.ceil}
    package[:dimensions] = {:length => @shipment.package_length,
                            :width => @shipment.package_width,
                            :height => @shipment.package_height,
                            :units => "IN" }  if @shipment.dimensions_available?

    if params[:format] == 'EPL2'
      begin
        label = fedex.label(:shipper => shipper,
                            :recipient => recipient,
                            :packages =>  [ package ],
                            :service_type => params[:service_type],
                            :shipping_details => shipping_details,
                            :label_specification => {
                                :image_type => "EPL2",
                                :label_stock_type => "STOCK_4X6"
                            })

        data = label.response_details[:completed_shipment_detail][:completed_package_details][:label][:parts][:image]
        label_data = Base64.decode64(data)

      rescue Exception => e
        flash[:error] = e.message
        Rails.logger.error e
        return redirect_to :back
      end

    else
      begin
        label = fedex.label(:filename => '/tmp/fedex_label.pdf',
                            :shipper => shipper,
                            :recipient => recipient,
                            :packages => packages,
                            :service_type => params[:service_type],
                            :shipping_details => shipping_details,
                            :debug => true
        )
      rescue Exception => e
        flash[:error] = e.message
        return redirect_to :back
      end
    end

    elem = label.response_details[:completed_shipment_detail][:shipment_rating][:shipment_rate_details]
    if elem.class == Array
      ship_cost = elem[0][:total_net_fed_ex_charge][:amount]
    else
      ship_cost = elem[:total_net_fed_ex_charge][:amount]
    end

    @shipment.update_attributes({tracking_number: label.tracking_number,
                                 ship_date: Time.now,
                                 status: 'shipped',
                                 ship_method: params[:service_type],
                                 ship_cost: ship_cost,
                                 label_data: label_data,
                                 label_format: params[:format]}
    )

    # Add OrderHistory record, mark order as shipped?
    OrderHistory.create order_id: @shipment.order_id,
                        user_id: current_user.id,
                        event_type: 'package_shipped',
                        amount: ship_cost,
                        system_name: 'fedex',
                        identifier: label.tracking_number,
                        comment:  params[:service_type],
                        data1: label_data,
                        data2: params[:format]

    @shipment.order.update_attribute(:status, 'shipped')
    redirect_to admin_store_shipment_path(@shipment)
  end


  private

  def shipment_params
    params.require(:shipment).permit(:drop_off_type, :package_weight, :package_length, :package_width, :package_height, :packaging_type)
  end
end
