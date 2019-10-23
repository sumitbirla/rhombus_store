require 'csv'
require 'fileutils'

class TransmitEdiOrdersJob < ActiveJob::Base
  queue_as :default


  def perform(fulfiller_id)
    @logger = Logger.new(Rails.root.join("log", "transmit_orders.log"))
    
    shipments = Shipment.where(status: :pending, fulfilled_by_id: fulfiller_id)
    return if shipments.length == 0
    
    fulfiller = Affiliate.find(fulfiller_id)
		file_path = Setting.get(shipments[0].order.domain_id, :ecommerce, 'EDI Path') + "/" + fulfiller.slug + "/outgoing/orders/orders_#{DateTime.now.strftime("%F_%H%M%S")}.csv"
		#file_path = "/Users/sbirla/Projects/edi/" + fulfiller.slug + "/outgoing/orders/orders_#{DateTime.now.strftime("%F_%H%M%S")}.csv" 
    website_name = Setting.get(Rails.configuration.domain_id, :system, "Website Name")
		
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
		
    
    # For packing slip download link
    token = Cache.setting(Rails.configuration.domain_id, :system, 'Security Token')
    website_url = Cache.setting(Rails.configuration.domain_id, :system, 'Website URL')
    
		csv = CSV.open(file_path, "wb")
		csv << headers
		
    shipments.each do |shp|
      @logger.info "Sending #{shp} to #{shp.fulfiller}"
      
      digest = Digest::MD5.hexdigest(shp.id.to_s + token) 
      
      begin
				packing_slip_url = [ "#{website_url}/admin/store/shipments/#{shp.id}/packing_slip?digest=#{digest}" ]
				FileUtils.mkdir_p("/home/#{fulfiller.slug}/outgoing/packing_slips")
				
				PdfDownloadJob.perform_now(packing_slip_url, "/home/#{fulfiller.slug}/outgoing/packing_slips/#{shp}.pdf")
				
    		shp.items.each do |si|
    			ap = AffiliateProduct.find_by(affiliate_id: shp.fulfiller.id, product_id: si.order_item.product_id)
			
    	  	csv << [
    				website_name,
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
    				"",
    				"" # ship_method
    			]
        end

        shp.update_column(:status, :transmitted)
      rescue => e
        @logger.error e
      end
    end
    
    system("chown #{fulfiller.slug} #{file_path}")
    @logger.info "Wrote file " + file_path
    
		csv.close
  end
	
end
