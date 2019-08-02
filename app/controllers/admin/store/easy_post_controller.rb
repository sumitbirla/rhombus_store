require 'easypost'

class Admin::Store::EasyPostController < Admin::BaseController

  def index
    @shipment = Shipment.find(params[:shipment_id])
		@shipment.packaging_type = 'YOUR PACKAGING' if @shipment.packaging_type.blank?
    
    # set ship date to tomorrow if after 7pm or Sunday
    if @shipment.ship_date.nil?
      t = Time.now
      @shipment.ship_date = Date.today
      @shipment.ship_date = Date.tomorrow if (t.wday == 7 || t.hour > 21)
    end
    
    # if identical shipment was recentely shipped with same contents, set box size and weight
    s = @shipment.similar_shipment
    
    @shipment.assign_attributes(
          packaging_type: s.packaging_type,
          package_weight: s.package_weight,
          package_height: s.package_height,
          package_length: s.package_length,
          package_width: s.package_width
    ) unless s.nil?
    
    @default_printer_id = Cache.setting(@shipment.order.domain_id, :shipping, "Default Label Printer ID") 
		@shipment.affiliate_shipping_account = @shipment.affiliate_shipping_available?
  end
  
  def rates
    @shipment = Shipment.find(params[:shipment_id])
    @shipment.assign_attributes(shipment_params)
    @default_printer_id = params[:printer_id]
    
    return render 'index' unless @shipment.valid?
		
    begin
      @ep_shipment = create_ep_shipment(@shipment)
      @cheapest_rate = @ep_shipment[:rates].min_by { |x| x[:rate].to_d } unless @ep_shipment[:rates].nil?
      
      if response && params[:ship_cheapest] == "true" && @cheapest_rate
        easypost_purchase(@shipment, @cheapest_rate[:id], @ep_shipment)
        @shipment.update_column(:affiliate_shipping_account, params[:affiliate_shipping_account] == "true")
        return redirect_to admin_store_shipment_path(@shipment)
      end
    rescue => e
      flash[:error] = e.message
    end
  
    render 'index'
  end
  
  # Purchases shipping for given shipment
  def buy
    shipment = Shipment.find(params[:shipment_id])
    shipment.update_column(:affiliate_shipping_account, params[:affiliate_shipping_account] == "true")
    EasyPost.api_key = shipment.easy_post_api_key
    
    begin
      ep_shipment = EasyPost::Shipment.retrieve(params[:ep_shipment_id])
      easypost_purchase(shipment, params[:rate_id], ep_shipment)  
    rescue => e
      flash[:error] = e.message + params[:ep_shipment_id]
      return redirect_back(fallback_location: admin_root_path)
    end
    
    redirect_to admin_store_shipment_path(shipment)
  end
  
  # Creates an EasyPost shipment object which contains rates
  def batch
    shp = Shipment.new(shipment_params)
    
    job_params = {
      shipment_ids: params[:shipment_ids],
      carrier: shp.carrier,
      service: shp.ship_method,
      packaging: shp.packaging_type,
      length: shp.package_length.to_f,
      width: shp.package_width.to_f,
      height: shp.package_height.to_f,
      weight: shp.package_weight.to_f,
      require_signature: shp.require_signature,
      print_epl: params[:print_epl] == "1",
      send_email: params[:send_email] == "1",
      ship_date: shp.ship_date.to_s,
      user_id: session[:user_id]
    }
    
    Shipment.where(id: params[:shipment_ids]).update_all(batch_status: "queued", batch_status_message: "")
    BatchShipJob.perform_later(job_params)
    
    redirect_to action: :batch_status, shipment_ids: params[:shipment_ids].join(".")
  end
  
  
  def batch_status
    @shipments = Shipment.where(id: params[:shipment_ids].split("."))
    
    respond_to do |format|
      format.html
      format.json { render json: @shipments, only: [:id, :status, :batch_status, :batch_status_message] }
    end
  end
  

  private

    def shipment_params
      params.require(:shipment).permit!
    end
    
    def create_ep_shipment(shipment)
  		if shipment.packaging_type == 'YOUR PACKAGING'
  			parcel = {
            :length => shipment.package_length, 
            :width => shipment.package_width,
            :height => shipment.package_height,
            :weight => shipment.package_weight * 16.0
          }
  		else
  			parcel = {
  				:predefined_package => shipment.packaging_type,
  				:weight => shipment.package_weight * 16.0
  			}
  		end
    
      options = { 
        :print_custom_1 => shipment.to_s,
        :date_advance => (shipment.ship_date - Date.today).to_i
      }
      options[:delivery_confirmation] = 'SIGNATURE' if shipment.require_signature
      
      # 3rd party billing  eg - "UPS:X823X4:US:07090"
      if shipment.third_party_billing
        carrier, acct, country, zip = shipment.order.affiliate.get_property("Shipping Account").split(":")
        options[:bill_third_party_account] = acct
        options[:bill_third_party_country] = country
        options[:bill_third_party_postal_code] = zip
      end
      
      EasyPost.api_key = shipment.easy_post_api_key
      
      # create customs information if required
      if (['APO', 'FPO', 'DPO'].include?(shipment.recipient_city) || shipment.recipient_country != 'US')
        customs_info = EasyPost::CustomsInfo.create(eel_pfc: 'NOEEI 30.37(a)',
                                                    customs_certify: true,
                                                    customs_signer: 'Tim Ackerman',
                                                    contents_type: 'merchandise',
                                                    contents_explanation: '',
                                                    restriction_type: 'none',
                                                    restriction_comments: '',
                                                    non_delivery_option: 'abandon',
                                                    customs_items: [{
                                                      description: 'Dog Treats',
                                                      quantity: 2,
                                                      weight: 6,
                                                      value: 80,
                                                      hs_tariff_number: 230910,
                                                      origin_country: 'US'
                                                    }]
                                                    )
      end
      
      response = EasyPost::Shipment.create(
          :to_address => {
            :name => shipment.recipient_name,
            :company => shipment.recipient_company,
            :street1 => shipment.recipient_street1,
            :street2 => shipment.recipient_street2,
            :city => shipment.recipient_city,
            :state => shipment.recipient_state,
            :zip => shipment.recipient_zip,
            :country => shipment.recipient_country,
            :phone => shipment.order.contact_phone,
            :email => shipment.order.notify_email
          },
          :from_address => {
            :name => shipment.ship_from_name,
            :company => shipment.ship_from_company,
            :street1 => shipment.ship_from_street1,
            :city => shipment.ship_from_city,
            :state => shipment.ship_from_state,
            :zip => shipment.ship_from_zip,
            :country => shipment.ship_from_country,
            :phone => shipment.ship_from_phone,
            :email => shipment.ship_from_email
          },
          :parcel => parcel,
          :options => options,
          :customs_info => customs_info
      ) 
    
      shipment.copy_easy_post(response)
      response
    end
    
    def easypost_purchase(shipment, rate_id, ep_shipment)
      
      EasyPost.api_key = shipment.easy_post_api_key
      response = ep_shipment.buy(:rate => {:id => rate_id})
      
      puts response.inspect
    
      shipment.copy_easy_post(response)
      shipment.status = 'shipped'
      shipment.save!
  
      OrderHistory.create order_id: shipment.order_id,
                                user_id: current_user.id,
                                event_type: 'package_shipped',
                                amount: shipment.ship_cost,
                                system_name: response[:selected_rate][:carrier],
                                identifier: shipment.tracking_number,
                                comment:  response[:selected_rate][:service]
    
      # Amazon orders need to be notified about shipment
      if shipment.order.sales_channel == "Amazon.com"
        AmazonFulfillmentJob.perform_later(shipment.id)
			elsif shipment.order.sales_channel == "shopify"
				ShopifyFulfillmentJob.perform_later(shipment.id)
			elsif shipment.order.sales_channel == "stockify"
				StockifyFulfillmentJob.perform_later(shipment.id)
      end
    
      unless params[:printer_id].blank?
        ShippingLabelJob.perform_later(session[:user_id], shipment.id, params[:printer_id])
        flash[:success] = "Shipping label sent to printer"
      end
    
      # email customer with tracking info if specified in settings
      if Cache.setting(shipment.order.domain_id, :shipping, "Auto Email Tracking") == "true"
        unless (shipment.order.sales_channel == "Amazon.com" || shipment.order.sales_channel == "shopify")
          OrderMailer.order_shipped(shipment.id, session[:user_id]).deliver_later
          flash[:info] = "Shipment confirmation sent to #{shipment.order.notify_email}"
        end
      end
      
    end

end
