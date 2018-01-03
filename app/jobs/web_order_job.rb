class WebOrderJob < ActiveJob::Base
  queue_as :default

  def perform(h)
    o = Order.find(h[:order_id])

    # order result of email blast?
    EmailBlast.where(uuid: h[:email_blast_uuid]).update_all("sales = sales + 1") unless h[:email_blast_uuid].blank?
    
    # referral rewards
    unless h[:referral_key].blank?
      referrer = User.find_by(referral_key: h[:referral_key])
      o.referred_by = referrer.id unless referrer.nil?
    end
    
    # affiliate credit
    unless h[:affiliate_campaign_id].blank?
      ac = AffiliateCampaign.find(h[:affiliate_campaign_id])
      
      unless ac.nil?
        o.affiliate_campaign_id = ac.id
        o.affiliate_id = ac.affiliate_id
        
        ac.increment!(:orders) 
      
        # create commission
        unless ac.sale_commission == 0.0
          amt = o.total * ac.sale_commission / 100.0
          user = User.find_by(affiliate_id: ac.affiliate_id)
        
          unless user.nil?
            Payment.create(payable_id: o.id, payable_type: :order, user_id: user.id, customer: false, amount: amt, memo: "commission")
          end
        end
        
      end
    end
    
    # set ship_by date
    if Date.today.cwday < 5
      o.ship_latest = Date.today + 1.day
    else
      o.ship_latest = Date.today + (8-Date.today.cwday).days
    end
    
    # IMPORTANT - save any changed to order
    o.save validate: false

    # update any voucher, coupon stats
    Coupon.increment_counter(:times_used, o.coupon_id) unless o.coupon_id.nil?
    
    # register voucher use
    o.voucher.update_attribute(:amount_used, o.voucher.amount_used + o.credit_applied) unless o.voucher_id.nil?
    
    # update daily_deal counts
    o.deal_items.each do |item|
      DailyDeal.where(id: item.daily_deal_id).update_all("number_sold = number_sold + #{item.quantity}")
    end
    
    # set up auto_ship items
    order_items = o.items.select { |x| x.autoship_months > 0 }
    order_items.each do |item|
      autoship = AutoShipItem.find_by(user_id: o.user_id, item_number: item.item_number)
      if autoship.nil?
        autoship = AutoShipItem.new(
                    user_id: o.user_id,
                    item_number: item.item_number,
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
    
    # email order confirmation
    OrderMailer.order_submitted(o.id, nil).deliver_later
    
  end
end
