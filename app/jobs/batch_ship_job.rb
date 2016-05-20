require 'easypost'

class BatchShipJob < ActiveJob::Base
  queue_as :shipping
  
  attr_accessor :logger

  def perform(params)
    @logger = Logger.new(Rails.root.join("log", "shipping.log"))
    
    Shipment.includes(:order).where(id: params[:shipment_ids]).each do |shp|
      begin 
        process_shipment(shp, params)
      rescue => e
        shp.update(batch_status_message: e.message)
        @logger.error e
      end
    end
  end
  
  
  def process_shipment(shp, params)
    @logger.info "Processing #{shp} #{shp.recipient_name}"
    
    shp.update(batch_status: "processing")
  
    shp.assign_attributes(
  	  carrier: params[:carrier],
      ship_method: params[:service],
      packaging_type: params[:packaging],
      package_weight: params[:weight],
      ship_date: params[:ship_date],
      require_signature: params[:require_signature],
      fulfilled_by_id: params[:user_id]
    )
    
    unless params[:package_length] == 0.0
      shp.assign_attributes(
        package_length: params[:length],
        package_width: params[:width],
        package_height: params[:height],
      )
    end
    
    # ship from address is already populated
    EasyPost.api_key = Cache.setting(shp.order.domain_id, :shipping, 'EasyPost API Key')
    ep_shipment = create_ep_shipment(shp)
    reply = ep_shipment.buy(
      :rate => ep_shipment.lowest_rate(carriers = [shp.carrier], services = [shp.ship_method])
    )
    
    #@logger.debug reply.inspect
    
    shp.copy_easy_post(reply)
    shp.status = 'shipped'
    shp.save

    OrderHistory.create(
      order_id: shp.order_id,
      user_id: params[:user_id],
      event_type: 'package_shipped',
      amount: shp.ship_cost,
      system_name: reply[:selected_rate][:carrier],
      identifier: shp.tracking_number,
      comment:  reply[:selected_rate][:service]
    )

    shp.order.update(status: 'shipped')
    shp.update(batch_status: "complete")
    
    if params[:send_email]
      unless shp.order.notify_email.include?("marketplace")
        OrderMailer.order_shipped(shp).deliver_later
      end
    end
    
    if params[:print_epl]
      shp.update(batch_status_message: "printing label")
      ShippingLabelJob.perform_now(params[:user_id], shp.id, "epl2")
    end

    shp.update(batch_status_message: "done")
  end
  
  
  def create_ep_shipment(shipment)
		if shipment.packaging_type == 'YOUR PACKAGING'
      
      #check if package dimensions have been specified
      if shipment.package_length.blank?
			  parcel = {
          :weight => shipment.package_weight * 16.0
        }
      else
			  parcel = {
          :length => shipment.package_length, 
          :width => shipment.package_width,
          :height => shipment.package_height,
          :weight => shipment.package_weight * 16.0
        }
      end
      
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
    
    EasyPost.api_key = Cache.setting(shipment.order.domain_id, :shipping, 'EasyPost API Key')
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
        :options => options
    ) 
    
    #shipment.copy_easy_post(response)
    response
  end
  
  
end
