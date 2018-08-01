require 'csv'

class TransmitEdiOrdersJob < ActiveJob::Base
  queue_as :default


  def perform(fulfiller_id)
    @logger = Logger.new(Rails.root.join("log", "transmit_orders.log"))
    
    shipments = Shipment.where(status: :pending, fulfilled_by_id: fulfiller_id)
    return if shipments.length == 0
    
		file_path = Setting.get('eCommerce', 'EDI Path') + "/" + shp.fulfiller.slug + "/outgoing/orders/order_#{shp}.csv" 
		# file_path = "/Users/sbirla/Projects/edi/" + shipments[0].fulfiller.slug + "/outgoing/orders/orders_#{DateTime.now.strftime("%F_%H%M%S")}.csv" 
		
		headers = [
			"customer_number",
      "po_number",
			"order_date",
			"requested_ship_date",
			"item_number",
			"item_description",
			"quantity",
			"item_amount",
			"extended_value",
			"affiliate_id",
      "affiliate_order_number",
			"shipping_name",
			"shipping_address1",
			"shipping_address2",
			"shipping_city",
			"shipping_state",
			"shipping_zip",
			"shipping_country",
			"shipping_phone",	
			"shipper",
			"ship_method"
		] 
		
		csv = CSV.open(file_path, "wb")
		csv << headers
		
    shipments.each do |shp|
      @logger.info "Sending #{shp} to #{shp.fulfiller}"
      
      begin
    		shp.items.each do |si|
    			ap = AffiliateProduct.find_by(affiliate_id: shp.fulfiller.id, product_id: si.order_item.product_id)
			
    	  	csv << [
    				Setting.get(:system, "Website Name"),
            shp.to_s,
    				shp.order.submitted.to_date,
    				shp.order.submitted.to_date,
    				ap.item_number,
    				ap.product.title,
    				si.quantity,
    				"", # item_amount
    				"", # extended_value
    				shp.order.affiliate.code,
            shp.order.external_order_name,
    				shp.recipient_name,
    				shp.recipient_street1,
    				shp.recipient_street2,
    				shp.recipient_city,
    				shp.recipient_state,
    				shp.recipient_zip,
    				shp.recipient_country,
    				shp.order.contact_phone,
    				"USPS",
    				"" # ship_method
    			]
        end

        shp.update_column(:status, :transmitted)
      rescue => e
        @logger.error e
      end
    end
    
    @logger.info "Wrote file " + file_path
    
		csv.close
  end
	
end
