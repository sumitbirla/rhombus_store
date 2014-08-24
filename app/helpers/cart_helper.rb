module CartHelper

  def apply_shipping(order)

    # order subtotal needs to be upto-date in order to see which bracket shipping falls in
    order.subtotal = 0.0
    order.items.each { |i| order.subtotal += i.quantity.to_d * i.unit_price }

    options = ShippingOption.where("max_order_amount >= ? and min_order_amount <= ? and active = ?", order.subtotal, order.subtotal, true)
    if options.length > 0
      selected_option = options.min_by { |x| x.base_cost }
      order.shipping_cost = selected_option.base_cost
      order.shipping_method = selected_option.name
    else
      order.shipping_cost = 0.0
      order.shipping_method = nil
    end
  end


  def apply_tax(order)
    zip = ZipCode.find_by(code: order.shipping_zip)

    unless zip.nil?
      # calculate subtotal first
      order.subtotal = 0.0
      order.items.each { |i| order.subtotal += i.quantity.to_d * i.unit_price }

      # determine tax
      order.tax_rate = zip.tax_rate
      order.tax_amount = order.subtotal * zip.tax_rate / 100.0

      # order total needs to be > $0.0 to apply tax
      order.tax_amount = 0.0 if order.subtotal - order.discount_amount - order.credit_applied <= 0.0

    else
      order.tax_rate = 0.0
      order.tax_amount = 0.0
    end

  end


  def update_totals(order)
    order.discount_amount = 0.0
    order.credit_applied = 0.0
    order.subtotal = 0.0
    order.items.each { |i| order.subtotal += i.quantity.to_d * i.unit_price }

    # any coupon
    if order.coupon_id
      coupon = order.coupon
      order.discount_amount = coupon.discount_amount if coupon.discount_amount
      order.discount_amount = (coupon.discount_percent * order.subtotal / 100.0).round(2) if coupon.discount_percent
    end

    # any voucher
    if order.voucher_id
      voucher = order.voucher
      order.credit_applied = voucher.voucher_group.value
    end

    # grant total
    order.total = order.subtotal + order.tax_amount + order.shipping_cost - order.discount_amount - order.credit_applied
    order.total = 0.0 if order.total < 0.0
  end

end