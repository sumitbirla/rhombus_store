require 'easypost'
require 'net/http'
require 'uri'


class Admin::Store::EasyPostController < Admin::BaseController

  def index
    @shipment = Shipment.find(params[:shipment_id])
		@shipment.packaging_type = 'YOUR PACKAGING' if @shipment.packaging_type.blank?
  end
  
  def rates
    @shipment = Shipment.find(params[:shipment_id])
    @shipment.assign_attributes(shipment_params)
		
     
    EasyPost.api_key = 'kB3ozMJpvdkpWxvT3eAnBw'

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
          :email => @shipment.order.notify_email 
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
        :options => {
          :print_custom_1 => @shipment.to_s
        }
      ) 
      
      Rails.cache.write("#{@shipment.id}-response", @response, expires_in: 30.minutes) 
      render 'index'
  end
  
  def label
    @shipment = Shipment.find(params[:shipment_id])
    
    ep_shipment = Rails.cache.read("#{@shipment.id}-response")
    chosen_rate = ep_shipment[:rates].find { |x| x[:id] == params[:rate_id]}
    
    response = ep_shipment.buy(:rate => {:id => params[:rate_id]})
    response = ep_shipment.label({'file_format' => params[:format]})
    
    if params[:format] == 'epl2'
      label_url = response[:postage_label][:label_epl2_url]
    elsif params[:format] == 'pdf'
      label_url = response[:postage_label][:label_pdf_url]
    end
    
    # download the label
    begin
      label_data = Base64.encode64(Net::HTTP.get(URI.parse(label_url)))
    rescue => e
      flash[:error] = "Error downloading shipping label: " + e.message
    end
    
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
    	ship_cost: response[:selected_rate][:rate],
    	tracking_number: response[:tracking_code],
    	label_format: params[:format].upcase,
    	label_data: label_data,
    	courier_data: response.to_json    	
    )
    
    redirect_to admin_store_shipment_path(@shipment)
  end


  private

    def shipment_params
      params.require(:shipment).permit(:ship_date, :package_weight, :package_length, :package_width, :package_height, :packaging_type)
    end

end
