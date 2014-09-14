require 'easypost'

class Admin::Store::EasyPostController < Admin::BaseController

  def index
    @shipment = Shipment.find(params[:shipment_id])
		@shipment.packaging_type = 'YOUR PACKAGING' if @shipment.packaging_type.blank?
  end
  
  def rates
    @shipment = Shipment.find(params[:shipment_id])
    @shipment.assign_attributes(shipment_params)
		
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
    
    options = { 
      :print_custom_1 => @shipment.to_s,
      :date_advance => (@shipment.ship_date - Date.today).to_i
    }
    options[:delivery_confirmation] = 'SIGNATURE' if @shipment.require_signature
    
    begin
      EasyPost.api_key = Cache.setting('Shipping', 'EasyPost API Key')
      @response = EasyPost::Shipment.create(
          :to_address => {
            :name => @shipment.recipient_name,
            :company => @shipment.recipient_company,
            :street1 => @shipment.recipient_street1,
            :street2 => @shipment.recipient_street2,
            :city => @shipment.recipient_city,
            :state => @shipment.recipient_state,
            :zip => @shipment.recipient_zip,
            :country => @shipment.recipient_country,
            :phone => @shipment.order.contact_phone,
            :email => @shipment.order.notify_email
          },
          :from_address => {
            :company => @shipment.ship_from_company,
            :street1 => @shipment.ship_from_street1,
            :city => @shipment.ship_from_city,
            :state => @shipment.ship_from_state,
            :zip => @shipment.ship_from_zip,
            :country => @shipment.ship_from_country,
            :phone => @shipment.ship_from_phone,
            :email => @shipment.ship_from_email
          },
          :parcel => parcel,
          :options => options
      ) 
      
      @shipment.copy_easy_post(@response)
    rescue => e
      flash[:error] = e.message
    end

    render 'index'
  end
  
  def label
    @shipment = Shipment.find(params[:shipment_id])
    
    ep_shipment = EasyPost::Shipment.retrieve(params[:ep_shipment_id])
    response = ep_shipment.buy(:rate => {:id => params[:rate_id]})
    
    @shipment.copy_easy_post(response)
    @shipment.status = 'shipped'
    @shipment.fulfilled_by_id = session[:user_id]
    @shipment.save
    
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
