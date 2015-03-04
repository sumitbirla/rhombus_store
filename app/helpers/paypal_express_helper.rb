module PaypalExpressHelper

  def get_setup_purchase_params(cart, request)

    # PayPal subtotal calculation includes discount and credit applied which appear
    # as line items with negative amounts
    items = get_items(cart)
    subtotal = items.sum { |x| x[:quantity] * x[:amount] }

    return to_cents(cart.total), {
        :ip => request.remote_ip,
        :return_url => url_for(:action => 'review', :only_path => false),
        :cancel_return_url => Cache.setting(:system, "Website URL") + "/cart",
        :subtotal => subtotal,
        :shipping => to_cents(cart.shipping_cost),
        :handling => 0,
        :tax =>  to_cents(cart.tax_amount),
        :allow_note =>  true,
        :items => items,
    }
  end

  def get_order_info(gateway_response)
    items = get_items(cart)
    subtotal = items.sum { |x| x[:quantity] * x[:amount] }

    {
        shipping_address: gateway_response.address,
        email: gateway_response.email,
        name: gateway_response.name,
        gateway_details: {
            :token => gateway_response.token,
            :payer_id => gateway_response.payer_id,
        },
        subtotal: subtotal,
        shipping: cart.shipping,
        total: cart.total,
    }
  end

  def get_purchase_params(cart, request)

    # PayPal subtotal calculation includes discount and credit applied which appear
    # as line items with negative amounts
    items = get_items(cart)
    subtotal = items.sum { |x| x[:quantity] * x[:amount] }

    return to_cents(cart.total), {
        :ip => request.remote_ip,
        :token => cart.paypal_token,
        :payer_id => cart.paypal_payer_id,
        :subtotal => subtotal,
        :shipping => to_cents(cart.shipping_cost),
        :handling => 0,
        :tax =>      to_cents(cart.tax_amount),
        :items =>    items,
    }
  end

  def get_shipping(cart)
    # define your own shipping rule based on your cart here
    # this method should return an integer
    cart.shipping_cost
  end

  def get_items(cart)
    items = cart.items.collect do |line_item|
      item = line_item
      {
          :name => item.item_description,
          :number => item.item_id,
          :quantity => item.quantity,
          :amount => to_cents(item.unit_price),
      }
    end

    if cart.discount_amount > 0.0
      items << {
        :name => "Promo Code Discount",
        :number => "PromoCode",
        :quantity => 1,
        :amount => to_cents(cart.discount_amount) * -1
      }
    end

    if cart.credit_applied > 0.0
      items << {
          :name => "Credit Applied",
          :number => "Credit",
          :quantity => 1,
          :amount => to_cents(cart.credit_applied) * -1
      }
    end

    items
  end


  def to_cents(money)
    (money*100).round
  end

end