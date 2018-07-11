require 'shopify_api'

class ShopifyFulfillmentJob < ActiveJob::Base
  queue_as :shopify
  
  # Uploads order fulfillment feed for a given shipment to Shopify. Given a shipment id, 
  # the items in the shipment as marked as shipped along with carrier and tracking code.
  #
  # @param shipment [Integer] id of the shipment that has been shipped.
  def perform(shipment_id)
    shp = Shipment.find(shipment_id)
		
		# Initialize shopify
		api_key = Cache.setting('eCommerce', 'Shopify API Key')
		api_secret = Cache.setting('eCommerce', 'Shopify API Secret')
		
		affiliate_id = shp.order.affiliate_id
		auth = Authorization.find_by(user_id: User.find_by(affiliate_id: affiliate_id).id)
		
		ShopifyAPI::Session.setup(api_key: api_key, secret: api_secret)
		session = ShopifyAPI::Session.new(auth.uid, auth.token)
		ShopifyAPI::Base.activate_session(session)
    
    f = ShopifyAPI::Fulfillment.new(order_id: shp.order.external_order_id,
																		tracking_number: shp.tracking_number, 
																		tracking_company: shp.courier_name,
																		line_items: [])
		
		shp.items.each { |i| f.line_items << { id: i.order_item.external_id } }
		f.save!
		f.complete
		
		shp.update_column(:external_id, f.id)
  end
end
