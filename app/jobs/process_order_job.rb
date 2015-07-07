class ProcessOrderJob < ActiveJob::Base
  queue_as :default

  def perform(order_id)
    
    o = Order.find(order_id)
    
    # email order confirmation
    OrderMailer.order_submitted(o.id, o.user_id).deliver_later
    
    # update any voucher, coupon stats
    Coupon.increment_counter(:times_used, o.coupon_id) unless o.coupon_id.nil?
    
    # register voucher use
    o.voucher.update_attribute(:amount_used, o.voucher.amount_used + o.credit_applied) unless o.voucher_id.nil?
    
    # update daily_deal counts
    o.deal_items.each do |item|
      DailyDeal.where(id: item.daily_deal_id).update_all("number_sold = number_sold + #{item.quantity}")
    end
    
    # create shipment if requested
    if Cache.setting(o.domain_id, :shipping, "Auto Create Shipment")
      CreateShipmentJob.perform_later(o.id)
    end
    
    ######  ac.increment!(:orders)
    o.affiliate_campaign.increment!(:orders) unless o.affiliate_campaign.nil?
    
    # set up auto_ship items
    
  end
end
