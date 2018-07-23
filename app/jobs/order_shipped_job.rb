class OrderShippedJob < ActiveJob::Base
  queue_as :default

  def perform(shipment_id)
    shp = Shipment.find(shipment_id)
    
    # First see if invoice needs to be created
    aff = shp.order.affiliate
    if aff && !aff.disable_invoicing
      
      invoice_amount = 0.0
      
      shp.items.each do |item|
        ap = AffiliateProduct.find_by(affiliate_id: aff.id, product_id: item.order_item.product_id)
        invoice_amount += ap.price + item.quantity
      end
      
      invoice_amount += shp.ship_cost || 0.0 unless aff.free_shipping
      shp.update_column(:invoice_amount, invoice_amount)
    
    elsif shp.order.affiliate_id.nil?
      shp.update_column(:invoice_amount, shp.order.total)
    end
    
    # Add a negative payment if order needs billing info
    unless (shp.invoice_amount.nil? || shp.payments.count > 0)
			
			if shp.external_name.blank?
				memo = shp.to_s
			else
				memo = shp.external_name
			end
			
      shp.payments.build(user_id: shp.order.user_id, 
                         affiliate_id: shp.order.affiliate_id,
                         amount: -1.0 * shp.invoice_amount, 
                         memo: "Fulfillment #{memo}")
      shp.save!
    end
    
  end
end
