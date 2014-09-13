require 'easypost'


class Admin::Store::EasyPostController < Admin::BaseController

  def index
    @shipment = Shipment.find(params[:shipment_id])
		@shipment.packaging_type = 'YOUR PACKAGING' if @shipment.packaging_type.blank?
  end
  
  def rates
    @shipment = Shipment.find(params[:shipment_id])
    @shipment.assign_attributes(shipment_params)
		
     
    EasyPost.api_key = Cache.setting('Shipping', 'EasyPost API Key')

		if @shipment.packaging_type == 'YOUR PACKAGING'
			parcel = {
          :length => @shipment.package_length, 
          :width => @shipment.package_width,
          :height => @shipment.package_height,
          :weight => @shipment.package_weight * 16.0
        }
		else
			parcel = {
				:predefined_package => @shipment.packaging_type,
				:weight => @shipment.package_weight * 16.0
			}
		end
    
    options = { :print_custom_1 => @shipment.to_s }
    options[:delivery_confirmation] = 'SIGNATURE' if @shipment.require_signature
    
    begin
      @response = EasyPost::Shipment.create(
          :to_address => {
            :name => @shipment.recipient_name,
            :company => @shipment.recipient_company,
            :street1 => @shipment.recipient_street1,
            :street2 => @shipment.recipient_street2,
            :city => @shipment.recipient_city,
            :state => @shipment.recipient_state,
            :zip => @shipment.recipient_zip,
            :country => 'US',
            :phone => @shipment.order.contact_phone,
            :email => @shipment.order.notify_email,
            :residential => 1
          },
          :from_address => {
            :company => @shipment.ship_from_company,
            :street1 => @shipment.ship_from_street1,
            :city => @shipment.ship_from_city,
            :state => @shipment.ship_from_state,
            :zip => @shipment.ship_from_zip,
            :country => 'US',
            :phone => '8557273337',
            :email => 'sumit@healthybreeds.com' 
          },
          :parcel => parcel,
          :options => options
      ) 
    rescue => e
      flash[:error] = e.message
    end
    #@response.insure(:amount => @shipment.insurance) if @shipment.insurance > 0.0 
    render 'index'
  end
  
  def label
    @shipment = Shipment.find(params[:shipment_id])
    ep_shipment = EasyPost::Shipment.retrieve(params[:ep_shipment_id])
    
    response = ep_shipment.buy(:rate => {:id => params[:rate_id]})
    
    parcel = response[:parcel]
		from = response[:from_address]
		to = response[:to_address]

    @shipment.update_attributes(

			ship_from_company: from[:company],
    	ship_from_street1: from[:street1],
    	ship_from_street2: from[:street2],
    	ship_from_city: from[:city],
    	ship_from_state: from[:state],
    	ship_from_zip: from[:zip],
    	ship_from_country: from[:country],

    	recipient_name: to[:name],
    	recipient_company: to[:company],
    	recipient_street1: to[:street1],
    	recipient_street2: to[:street2],
    	recipient_city: to[:city],
    	recipient_state: to[:state],
    	recipient_zip: to[:zip],
    	recipient_country: to[:country],

			status: "shipped",

			packaging_type: parcel[:predefined_package] || 'YOUR PACKAGING',
    	package_width: parcel[:width],
    	package_length: parcel[:length],
    	package_height: parcel[:height],
    	package_weight: parcel[:weight] / 16.0,

    	ship_date: DateTime.now,
    	ship_method: response[:selected_rate][:carrier] + ' ' + response[:selected_rate][:service],
      require_signature: response[:options][:delivery_confirmation] == 'SIGNATURE',
    	ship_cost: response[:selected_rate][:rate],
    	tracking_number: response[:tracking_code],
    	label_format: response[:postage_label][:label_file_type],
    	label_data: response[:postage_label][:label_url],
    	courier_data: response.to_json    	
    )
    
    OrderHistory.create order_id: @shipment.order_id,
                              user_id: current_user.id,
                              event_type: 'package_shipped',
                              amount: @shipment.ship_cost,
                              system_name: response[:selected_rate][:carrier],
                              identifier: @shipment.tracking_number,
                              comment:  response[:selected_rate][:service]

    @shipment.order.update_attribute(:status, 'shipped')
    
    redirect_to admin_store_shipment_path(@shipment)
  end


  private

    def shipment_params
      params.require(:shipment).permit(:ship_date, :package_weight, :package_length, :package_width, :package_height, :packaging_type,
        :require_signature, :insurance)
    end

end
