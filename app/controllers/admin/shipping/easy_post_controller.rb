require 'easypost'
require 'net/http'
require 'uri'


class Admin::Shipping::EasyPostController < Admin::BaseController

  def index
    @shipment = Shipment.find(params[:shipment_id])
  end
  
  def rates
    @shipment = Shipment.find(params[:shipment_id])
    @shipment.assign_attributes(shipment_params)
     
    EasyPost.api_key = 'kB3ozMJpvdkpWxvT3eAnBw'
    
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
        :parcel => {
          :length => @shipment.package_length, 
          :width => @shipment.package_width,
          :height => @shipment.package_height,
          :weight => @shipment.package_weight * 16.0
        },
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
    @shipment.status = "shipped"
    @shipment.packaging_type = parcel[:predefined_package] || 'Package'
    @shipment.package_width = parcel[:width]
    @shipment.package_length = parcel[:length]
    @shipment.package_height = parcel[:height]
    @shipment.package_weight = parcel[:weight] / 16.0
    @shipment.ship_date = DateTime.now
    @shipment.ship_method = response[:selected_rate][:carrier] + ' ' + response[:selected_rate][:service]
    @shipment.ship_cost = response[:selected_rate][:rate]
    @shipment.tracking_number = response[:tracking_code]
    @shipment.label_format = params[:format].upcase
    @shipment.label_data = label_data
    @shipment.courier_data = response.to_json

    from = response[:from_address]
    @shipment.ship_from_company = from[:company]
    @shipment.ship_from_street1 = from[:street1]
    @shipment.ship_from_street2 = from[:street2]
    @shipment.ship_from_city = from[:city]
    @shipment.ship_from_state = from[:state]
    @shipment.ship_from_zip = from[:zip]
    @shipment.ship_from_country = from[:country]

    to = response[:to_address]
    @shipment.recipient_name = to[:name]
    @shipment.recipient_company = to[:company]
    @shipment.recipient_street1 = to[:street1]
    @shipment.recipient_street2 = to[:street2]
    @shipment.recipient_city = to[:city]
    @shipment.recipient_state = to[:state]
    @shipment.recipient_zip = to[:zip]
    @shipment.recipient_country = to[:country]
    
    @shipment.save
    
    redirect_to admin_store_shipment_path(@shipment)
  end


  private

    def shipment_params
      params.require(:shipment).permit(:ship_date, :package_weight, :package_length, :package_width, :package_height, :packaging_type)
    end

end
