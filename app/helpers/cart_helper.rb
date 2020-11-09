module CartHelper

  def apply_shipping(order)
    # daily_deals have their own shipping rules
    order.shipping_cost = order.deal_items.sum { |x| x.daily_deal.shipping_cost * x.quantity }
    order.shipping_method = nil

    options = ShippingOption.where("domain_id = ? and max_order_amount >= ? and min_order_amount <= ? and active = ?", order.domain_id, order.subtotal, order.subtotal, true)
    if options.length > 0
      selected_option = options.min_by { |x| x.base_cost }

      # apply shipping cost if > 0 only if there are non-deal items
      if selected_option.base_cost > 0.0 && order.non_deal_items.length > 0
        order.shipping_cost += selected_option.base_cost
        order.shipping_method = selected_option.name
      elsif selected_option.base_cost == 0.0
        order.shipping_cost = selected_option.base_cost
        order.shipping_method = selected_option.name
      end
    end
  end


  def apply_tax(order)
    order.tax_rate = 0.0
    order.tax_amount = 0.0

    # Do not add tax to tax_exempt customers
    if order.user && order.user.affiliate && order.user.affiliate.tax_exempt
      return
    end

    zip = ZipCode.find_by(code: order.shipping_zip)
    unless zip.nil?
      # determine tax
      order.tax_rate = zip.tax_rate
      order.tax_amount = (order.subtotal - order.discount_amount - order.credit_applied - order.fb_discount) * zip.tax_rate / 100.0

      # order total needs to be > $0.0 to apply tax
      order.tax_amount = 0.0 if order.tax_amount <= 0.0
    end
  end


  def update_totals(order)
    order.discount_amount = 0.0
    order.credit_applied = 0.0
    order.subtotal = 0.0
    order.items.each { |i| order.subtotal += i.quantity.to_d * i.unit_price }

    if order.shipping_country == 'US'
      apply_shipping(order)
    end

    # any coupon
    if order.coupon_id
      coupon = order.coupon
      order.discount_amount = coupon.discount_amount if coupon.discount_amount
      order.discount_amount = (coupon.discount_percent * order.subtotal / 100.0).round(2) if coupon.discount_percent
      order.shipping_cost = 0.0 if coupon.free_shipping
    end

    # any voucher
    if order.voucher_id
      voucher = order.voucher
      order.credit_applied = voucher.voucher_group.value
    end

    apply_tax(order)

    # grand total
    order.total = order.subtotal + order.tax_amount + order.shipping_cost - order.discount_amount - order.credit_applied - order.fb_discount
    order.total = 0.0 if order.total < 0.0
  end

end