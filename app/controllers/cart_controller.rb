class CartController < ApplicationController

  include CartHelper
  include PaypalExpressHelper
  
  force_ssl  if Rails.env.production?
  layout 'single_column'
  
  
  def load_or_create_order
    key = cookies[:cart]
    
    # create new order if necessary
    if key.blank?
      key = SecureRandom.hex 
      cookies[:cart] = key
    end    
    
    # load existing order from database
    order = Order.includes(:items).find_by(cart_key: key)
    if order.nil?
      order = Order.new(cart_key: key, status: 'in cart', payment_method: 'CREDIT_CARD')
      order.save validate: false
    end
    
    order
  end
  
  
  # GET /cart
  
  def index
    key = cookies[:cart]
    @order = Order.includes(:items, [items: [:product, :affiliate]]).find_by(cart_key: key) unless key.nil?
  end


  # GET /cart/add

  def add
    
    order = load_or_create_order
    
    # iterate through multiple items being added to cart
    # key = {product-id}-{affiliate-id}-{variation}
    params.each do |key, val|
      next unless key.include?('qty-')
      
      key = key.split('-')
      affiliate_id = nil
      variation = nil
      
      product_id = key[1].to_i
      affiliate_id = key[2].to_i unless key.length < 3
      variation = key[3] unless key.length < 4
      quantity = val.to_i
      
      next unless quantity > 0
      p = Product.find(product_id)
      
      #check if item already exists
      item = order.items.find { |i| i.product_id == product_id && i.affiliate_id == affiliate_id && i.variation == variation }
      if item.nil?

        item = OrderItem.new order_id: order.id,
                product_id: product_id,
                affiliate_id: affiliate_id,
                variation: variation,
                quantity: quantity,
                unit_price: p.price,
                item_description: p.title

        item.item_id = p.sku
        item.item_id += "-" + Affiliate.find(affiliate_id).code unless affiliate_id.nil?
        item.item_id += "-" + variation unless variation.nil?

        order.items << item
      else
        item.quantity += quantity
        item.save
      end
    end
    
    update_totals order
    order.save validate: false
    
    redirect_to action: 'index'
  end
  
  
  # GET /cart/add_deal
  def add_deal
    dd = DailyDeal.find(params[:daily_deal_id])
    
    unless dd.active && dd.start_time < DateTime.now && dd.end_time > DateTime.now
      flash[:error] = "This deal is not currently active."
      return redirect_to action: 'index'
    end
    
    if dd.number_sold >= dd.max_sales
      flash[:error] = "Sorry, this deal is sold out."
      return redirect_to action: 'index'
    end
    
    order = load_or_create_order
    
    # add item to cart
    item = order.items.find { |i| i.daily_deal_id == dd.id }
    if item.nil?

      item = OrderItem.new order_id: order.id,
              daily_deal_id: dd.id,
              quantity: params[:qty],
              unit_price: dd.deal_price,
              item_description: dd.title,
              item_id: "DEAL#{dd.id}"

      order.items << item
    else
      item.quantity += params[:qty].to_i
      item.save
    end
    
    if dd.max_per_user && (item.quantity > dd.max_per_user)
      flash[:error] = "Sorry, this deal is limited to #{dd.max_per_user} per customer."
      item.update_attribute(:quantity, dd.max_per_user)
    end
    
    update_totals order
    order.save validate: false
    
    return redirect_to action: 'index'
  end
  

  def remove
    id = params[:id].to_i
    order = Order.includes(:items).find_by(cart_key: cookies[:cart])

    if order != nil
      item = order.items.find { |t| t.id == id }
      unless item.nil?
        order.items.destroy(item)

        # update order or delete altogether if no items left
        if order.items.length > 0
          update_totals order
          order.save validate: false
        else
          order.destroy
        end
      end
    end

    redirect_to :back
  end

  
  def update
    order = Order.includes(:items).find_by(cart_key: cookies[:cart])
    
    # iterate through items
    params.each do |key, val|
      next unless key.include?('qty-')
      
      item_id = key[4..-1].to_i
      quantity = val.to_i
      
      item = order.items.find { |item| item.id == item_id }
      next if item.nil?
      
      if quantity > 0
        item.quantity = quantity
        
        # special check for daily deals
        if item.daily_deal && item.daily_deal.max_per_user && (item.quantity > item.daily_deal.max_per_user)
          flash[:error] = "Sorry, #{item.item_id} is limited to #{item.daily_deal.max_per_user} per customer."
          item.quantity = item.daily_deal.max_per_user
        end
        
        item.save
      else
        order.items.destroy(item)
      end 
    end

    # update order or delete altogether if no items left
    if order.items.length > 0
      update_totals order
      order.save validate: false
    else
      order.destroy
    end
    
    flash[:notice] = 'Your shopping cart has been updated.'
    redirect_to :back
  end
  
  
  def checkout
      @order = Order.includes(:items).find_by(cart_key: cookies[:cart])
      redirect_to action: 'index' if @order.nil? || @order.items.length == 0

      # retrieve info from previous order if user is logged in
      if @order.user_id.nil? && !session[:user_id].nil?
        @order.user_id = session[:user_id]
        
        previous_order = Order.order('submitted DESC').find_by(user_id: @order.user_id, status: ['submitted', 'completed', 'shipped'])
        unless previous_order.nil?
          @order.shipping_name = previous_order.shipping_name
          @order.shipping_street1 = previous_order.shipping_street1
          @order.shipping_street2 = previous_order.shipping_street2
          @order.shipping_city = previous_order.shipping_city
          @order.shipping_state = previous_order.shipping_state
          @order.shipping_zip = previous_order.shipping_zip
          @order.shipping_country = previous_order.shipping_country
          
          @order.notify_email = previous_order.notify_email
          @order.contact_phone = previous_order.contact_phone
        else
          user = User.find(session[:user_id])
          @order.notify_email = user.email
          @order.contact_phone = user.phone
        end
      end

      # set payment_method depending on total.  PAYPAL would never reach this point
      @order.payment_method = @order.total > 0.0 ? "CREDIT_CARD" : "NO_BILLING"
  end
  
  
  def checkout_update  
    @order = Order.includes(:items).find_by(cart_key: cookies[:cart])
    @order.assign_attributes(order_params)

    # update billing name otherwise credit card validation will fail
    if @order.paid_with_card? && @order.same_as_shipping == '1'
      @order.billing_name = @order.shipping_name
      @order.billing_street1 = @order.shipping_street1
      @order.billing_street2 = @order.shipping_street2
      @order.billing_city = @order.shipping_city
      @order.billing_state = @order.shipping_state
      @order.billing_zip = @order.shipping_zip
      @order.billing_country = @order.shipping_country
    end
    
    if @order.valid?
      update_totals(@order)
      @order.save(validate: false)
      return redirect_to action: 'review'
    end

    render 'checkout'
  end
  
  
  def review
    @order = Order.includes(:items).find_by(cart_key: cookies[:cart])
    redirect_to action: 'index' if @order.nil? || @order.items.length == 0
  end
  
  
  def submit
    @order = Order.includes(:items).find(params[:id])
    @order.user_id = session[:user_id] if @order.user_id.nil?   # attach order to logged-in user

    # Double check if voucher is not being reused.  this can happen if user has multiple
    # carts in different browsers, all not check-out yet, but voucher applied, i.e. the 
    # voucher hasn't been marked as claimed yet.
    unless @order.voucher_id.nil?
      voucher = Voucher.find(@order.voucher_id)
      if voucher.amount_used + @order.credit_applied > voucher.voucher_group.value
        @order.errors.add :base, "Voucher has already been used.  Please review changed to your order."
        @order.voucher_id = nil
        
        update_totals @order
        @order.save
        
        return render 'review'
      end
    end


    if @order.payment_method == 'PAYPAL'

      gateway = ActiveMerchant::Billing::PaypalExpressGateway.new(
          :login => Cache.setting('eCommerce', 'PayPal API Username'),
          :password => Cache.setting('eCommerce', 'PayPal API Password'),
          :signature => Cache.setting('eCommerce', 'PayPal Signature'),
      )

      total_as_cents, purchase_params = get_purchase_params(@order, request)
      response = gateway.purchase(total_as_cents, purchase_params)

      unless response.success?
        flash[:error] = "PayPal processing failed: #{response.message}"
        return render 'review'
      end

      @order.status = 'submitted'
      @order.submitted = Time.now
      @order.save validate: false
      
      # create payment entries
      Payment.create(payable_id: @order.id, payable_type: :order, amount: @order.total * -1.0, memo: 'invoice')
      Payment.create(payable_id: @order.id, payable_type: :order, amount: @order.total, memo: 'PayPal Payment', transaction_id: response.authorization)

      # add order history row
      OrderHistory.create order_id: @order.id, user_id: @order.user_id, amount: @order.total,
                          event_type: 'paypal_payment', system_name: 'PayPal', identifier: response.authorization,
                          comment: @order.notify_email

    elsif @order.payment_method == "CREDIT_CARD"
      
      active_gw = Cache.setting('eCommerce', 'Payment Gateway')

      if active_gw == 'Authorize.net'
        gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(
            :login => Cache.setting('eCommerce', 'Authorize.Net Login ID'),
            :password => Cache.setting('eCommerce', 'Authorize.Net Transaction Key'),
            :test => false
        )
      elsif active_gw == 'Stripe'
        gateway = ActiveMerchant::Billing::StripeGateway.new(
            :login => Cache.setting('eCommerce', 'Stripe Secret Key')
        )  
      else
        flash[:error] = "Payment gateway is not set up."
        return render 'review'
      end 

      customer_name = @order.billing_name
      customer_name = @order.user.name unless @order.user_id.nil?
      
      purchase_options = {
        :ip => request.remote_ip,
        :order_id => @order.id,
        :customer => customer_name,
        :billing_address => {
          :name     => @order.billing_name,
          :address1 => @order.billing_street1,
          :city     => @order.billing_street2,
          :state    => @order.billing_state,
          :zip      => @order.billing_zip
      }}

      response = gateway.purchase(@order.total_cents, @order.credit_card, purchase_options)

      # credit cart authorization failed?
      unless response.success?
        @order.errors.add :base, response.message
        return render 'review'
      end

      @order.status = 'submitted'
      @order.submitted = Time.now
      @order.cc_code = nil
      @order.cc_number = @order.credit_card.display_number
      @order.save validate: false

      # create payment entries
      Payment.create(payable_id: @order.id, payable_type: :order, amount: @order.total * -1.0, memo: 'invoice')
      Payment.create(payable_id: @order.id, payable_type: :order, amount: @order.total, memo: @order.cc_number, transaction_id: response.authorization)
      
      # add order history row
      OrderHistory.create order_id: @order.id, user_id: @order.user_id, amount: @order.total,
                          event_type: 'cc_authorization', system_name: active_gw, identifier: response.authorization,
                          comment: "Successfully charged #{@order.cc_number}"

    else # NO_BILLING
      @order.status = 'submitted'
      @order.submitted = Time.now
      @order.save validate: false
    end


    
    # update any voucher, coupon stats
    Coupon.increment_counter(:times_used, @order.coupon_id) unless @order.coupon_id.nil?
    
    unless @order.voucher_id.nil?
      voucher = @order.voucher
      voucher.update_attribute(:amount_used, voucher.amount_used + @order.credit_applied)
    end
    
    # affiliate credit
    unless cookies[:acid].nil?
      ac = AffiliateCampaign.find(cookies[:acid])
      unless ac.nil?
        ac.increment!(:orders)
        @order.affiliate_campaign_id = ac.id
        
        # add commission to payments table?
      end
    end
    
    # referral rewards
    unless cookies[:refkey].nil?
      referrer = User.find_by(referral_key: cookies[:refkey])
      unless referrer.nil?
        @order.referred_by = referrer.id
        
        # apply rewards programs
      end
    end
    
    @order.save validate: false
    
    sql = ""
    
    # order result of email blast?
    unless cookies[:ebuuid].nil?
      sql += "UPDATE mktg_email_blasts SET sales=sales+1 WHERE uuid='#{cookies[:ebuuid]}'; "
    end
    
    # update daily_deal counts
    @order.items.each do |item|
      unless item.daily_deal_id.nil?
        sql += "UPDATE store_daily_deals SET number_sold=number_sold+#{item.quantity} WHERE id=#{item.daily_deal_id}; "
      end
    end
    
    # inventory update?
    #sql = ""
    #@order.items.each do |item|
    #  sql = sql + "UPDATE store_products SET committed = committed + #{item.quantity} WHERE id = #{item.product_id}; "
    #end
    
    begin
      ActiveRecord::Base.connection.execute(sql) unless sql.blank?
    rescue => e
      logger.error e
    end

    # email order confirmation to customer
    begin
      OrderMailer.order_submitted_email(@order).deliver
    rescue => e
      logger.error e
    end
    
    
    # delete cart cookie and display confirmation
    cookies.delete :cart
    session[:order_id] = @order.id
    
    redirect_to action: 'submitted', id: @order.id
    return
    
  end
  
  
  def submitted
      @order = Order.includes(:items).find(session[:order_id])
  end
  

  def applycode

    # load order
    applied = false
    order = Order.includes(:items).find_by(cart_key: cookies[:cart])

    # test if code is a coupon code
    coupon = Coupon.find_by(code: params[:code])
    unless coupon.nil?

      if (coupon.times_used > coupon.max_uses)
        flash[:notice] = 'This coupon is no longer available.'
      elsif coupon.start_time > Time.now || coupon.expire_time < Time.now
        flash[:notice] = 'This coupon has expired.'
      elsif coupon.min_order_amount && order.subtotal < coupon.min_order_amount
        flash[:notice] = "This coupon is only valid for orders over #{number_to_currency(coupon.min_order_amount)}."
      else
        order.coupon_id = coupon.id
        update_totals order
        order.save validate: false

        applied = true
        flash[:notice] = "Coupon code '#{coupon.code}' has been applied to your order."
      end

      # test if code is a voucher code
    else
      voucher = Voucher.find_by(code: params[:code])
      unless voucher.nil?
        if voucher.amount_used >= voucher.voucher_group.value
          flash[:notice] = 'This voucher has already been claimed.'
        elsif voucher.voucher_group.expires < Time.now
          flash[:notice] = 'This voucher has expired.'
        else
          order.voucher_id = voucher.id
          amt = voucher.voucher_group.value
          update_totals order
          order.save validate: false

          applied = true
          flash[:notice] = "A credit of $#{amt} has been applied to your order."
        end
      end
    end

    flash[:notice] = "Coupon or voucher code not found." unless applied
    redirect_to :back
  end
  
  
  private
  
    def order_params
      params.require(:order).permit(:shipping_name, :shipping_street1, :shipping_street2, :shipping_city, :shipping_state, 
      :shipping_zip, :shipping_country, :contact_phone, :billing_name, :billing_street1, :billing_street2, :billing_city,
      :billing_state, :billing_zip, :billing_country, :cc_type, :cc_number, :cc_expiration_month, :cc_expiration_year,
      :cc_code, :notify_email, :customer_note, :payment_method, :same_as_shipping, :user_id, :sales_channel)
    end
  
end
