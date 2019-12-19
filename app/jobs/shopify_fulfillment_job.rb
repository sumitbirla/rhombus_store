require 'shopify_api'

class ShopifyFulfillmentJob < ActiveJob::Base
  queue_as :shopify
  
  # Uploads order fulfillment feed for a given shipment to Shopify. Given a shipment id, 
  # the items in the shipment as marked as shipped along with carrier and tracking code.
  #
  # @param shipment [Integer] id of the shipment that has been shipped.
  def perform(shipment_id)
    @logger = Logger.new(Rails.root.join("log", "tracking.log"))
    shp = Shipment.find(shipment_id)
    
    @logger.info "Sending tracking information for #{shp} [#{shp.order.external_order_name}] to Shopify"
		
		# Initialize shopify
		api_key = Setting.get(shp.order.domain_id, :ecommerce, 'Shopify API Key')
		api_secret = Setting.get(shp.order.domain_id, :ecommerce, 'Shopify API Secret')
		
		affiliate_id = shp.order.affiliate_id
		auth = Authorization.find_by(user_id: User.find_by(affiliate_id: affiliate_id).id)
		
		ShopifyAPI::Session.setup(api_key: api_key, secret: api_secret)
		session = ShopifyAPI::Session.new(auth.uid, auth.token)
		ShopifyAPI::Base.activate_session(session)
    
		if shp.external_id.blank?
      # find fulfillment service first
      fs = ShopifyAPI::FulfillmentService.find(:all).find { |x| x.handle == 'stock-on-demand' }
      raise "FulfillmentService 'stock-on-demand' not found.  Cannot update tracking." if fs.nil?
      
    	f = ShopifyAPI::Fulfillment.new(order_id: shp.order.external_order_id, location_id: fs.location_id, line_items: [])
			shp.items.each do |i| 
        next unless i.special_status.downcase == "shipped"
        f.line_items << { id: i.order_item.external_id }
      end
		else
			f = ShopifyAPI::Fulfillment.where(id: shp.external_id, order_id: shp.order.external_order_id).first
			f[:prefix_options] = { :order_id => shp.order.external_order_id }
		end
		
		f.tracking_numbers = [ shp.tracking_number ]
		f.tracking_company = shp.courier_name
		
    if f.save
		  f.complete
		  shp.update_columns(external_id: f.id, external_name: f.name)
    else
      @logger.error f.errors.full_messages
    end
  end
end
