class ProcessOrderJob < ActiveJob::Base
  queue_as :default

  def perform(order_id)
    
    o = Order.find(order_id)
    
    # email order confirmation
    OrderMailer.order_submitted(o.id, nil).deliver_later
    
    # create shipment if requested
    if Cache.setting(o.domain_id, :shipping, "Auto Create Shipment")
      CreateShipmentJob.perform_later(o.id)
    end
    
    # update any voucher, coupon stats
    Coupon.increment_counter(:times_used, o.coupon_id) unless o.coupon_id.nil?
    
    # register voucher use
    o.voucher.update_attribute(:amount_used, o.voucher.amount_used + o.credit_applied) unless o.voucher_id.nil?
    
    # update daily_deal counts
    o.deal_items.each do |item|
      DailyDeal.where(id: item.daily_deal_id).update_all("number_sold = number_sold + #{item.quantity}")
    end
    
    # Affiliate tracking and commissions
    unless o.affiliate_campaign.nil?
      o.affiliate_campaign.increment!(:orders) 
      
      # create commission
      unless o.affiliate_campaign.sale_commission == 0.0
        amt = o.total * o.affiliate_campaign.sale_commission / 100.0
        user = User.find_by(affiliate_id: o.affiliate_campaign.affiliate.id)
        
        unless user.nil?
          Payment.create(payable_id: o.id, payable_type: :order, user_id: user.id, customer: false, amount: amt, memo: "commission")
        end
      end
    end
    
    # set up auto_ship items
    order_items = o.items.select { |x| x.autoship_months > 0 }
    order_items.each do |item|
      autoship = AutoShipItem.find_by(user_id: o.user_id, item_id: item.item_id)
      if autoship.nil?
        autoship = AutoShipItem.new(
                    user_id: o.user_id,
                    item_id: item.item_id,
                    description: item.item_description,
                    product_id: item.product_id,
                    affiliate_id: item.affiliate_id,
                    variation: item.variation,
                    quantity: item.quantity, 
                    status: :active)
      end
      
      autoship.days = item.autoship_months * 30
      autoship.last_shipped = Date.today
      autoship.next_ship_date = Date.today + autoship.days.days
      autoship.save
    end
    
  end
end
