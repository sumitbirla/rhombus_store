require 'csv'

class TransmitEdiOrderJob < ActiveJob::Base
  queue_as :default

  def perform(shipment_id)
		shp = Shipment.find(shipment_id)
		# file_path = Setting.get('eCommerce', 'EDI Path') + "/" + shp.fulfiller.slug + "/outgoing/orders/order_#{shp}.csv" 
		file_path = "/Users/sbirla/Projects/edi/" + shp.fulfiller.slug + "/outgoing/orders/order_#{shp}.csv" 
		
		headers = [
			"customer_number",
			"order_date",
			"requested_ship_date",
			"po_number",
			"stockify_po",
			"item_number",
			"item_description",
			"quantity",
			"item_amount",
			"extended_value",
			"affiliate_id",
			"shipping_name",
			"shipping_address1",
			"shipping_address2",
			"shipping_city",
			"shipping_state",
			"shipping_zip",
			"shipping_country",
			"shipping_phone",
			"affiliate_order_number",
			"shipper",
			"ship_method"
		] 
		
		CSV.open(file_path, "wb") do |csv|
		  csv << headers
			
			shp.items.each do |si|
				ap = AffiliateProduct.find_by(affiliate_id: shp.fulfiller.id, product_id: si.order_item.product_id)
				
		  	csv << [
					"customer_number",
					shp.order.submitted.to_date,
					shp.order.submitted.to_date,
					shp.to_s,
					"stockify_po",
					ap.item_number,
					ap.product.title,
					si.quantity,
					"item_amount",
					"extended_value",
					"affiliate_id",
					shp.recipient_name,
					shp.recipient_street1,
					shp.recipient_street2,
					shp.recipient_city,
					shp.recipient_state,
					shp.recipient_zip,
					shp.recipient_country,
					shp.order.contact_phone,
					"affiliate_order_number",
					"shipper",
					"ship_method"
				]
			end
		end
		
		shp.update_column(:status, :transmitted)
  end
	
end
