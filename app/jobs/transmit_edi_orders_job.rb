require 'csv'

class TransmitEdiOrdersJob < ActiveJob::Base
  queue_as :default


  def perform(fulfiller_id)
    @logger = Logger.new(Rails.root.join("log", "transmit_orders.log"))
    
    shipments = Shipment.where(status: :pending, fulfilled_by_id: fulfiller_id)
    return if shipments.length == 0
    
    fulfiller = Affiliate.find(fulfiller_id)
		file_path = Setting.get('eCommerce', 'EDI Path') + "/" + fulfiller.slug + "/outgoing/orders/orders_#{DateTime.now.strftime("%F_%H%M%S")}.csv"
		#file_path = "/Users/sbirla/Projects/edi/" + fulfiller.slug + "/outgoing/orders/orders_#{DateTime.now.strftime("%F_%H%M%S")}.csv" 
		
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
			"ship_from_name",
			"ship_from_address1",
			"ship_from_address2",
			"ship_from_city",
			"ship_from_state",
			"ship_from_zip",
			"ship_from_country",
			"ship_from_phone",
			"ship_to_name",
			"ship_to_address1",
			"ship_to_address2",
			"ship_to_city",
			"ship_to_state",
			"ship_to_zip",
			"ship_to_country",
			"ship_to_phone",	
			"shipper",
			"ship_method"
		] 
		
		csv = CSV.open(file_path, "wb")
		csv << headers
		
    shipments.each do |shp|
      @logger.info "Sending #{shp} to #{shp.fulfiller}"
      
      begin
    		shp.items.each do |si|
    			ap = AffiliateProduct.find_by(affiliate_id: shp.order.affiliate_id, product_id: si.order_item.product_id)
			
    	  	csv << [
    				Setting.get(:system, "Website Name"),
            shp.to_s,
    				shp.order.submitted.to_date,
    				shp.order.submitted.to_date,
    				ap.item_number,
    				ap.product.title,
    				si.quantity,
    				ap.price, # item_amount
    				"", # extended_value
    				shp.order.affiliate.code,
            shp.order.external_order_name,
    				shp.order.affiliate.name,
    				fulfiller.street1,
    				fulfiller.street2,
    				fulfiller.city,
    				fulfiller.state,
    				fulfiller.zip,
    				fulfiller.country,
    				fulfiller.phone,
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
