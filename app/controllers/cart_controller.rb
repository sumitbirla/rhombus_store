class CartController < ApplicationController

  include CartHelper
  include PaypalExpressHelper
  include ActionView::Helpers::NumberHelper
  
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
    order = Order.includes(:items, [items: [:product, :affiliate]]).find_by(cart_key: key)
    if order.nil?
      order = Order.new(cart_key: key, 
                        status: 'in cart', 
                        payment_method: 'CREDIT_CARD', 
                        domain_id: Rails.configuration.domain_id,
                        sales_channel: Cache.setting(Rails.configuration.domain_id, :system, "Website Name"))
      order.save validate: false
    end
    
    order
  end
  
  
  # GET /cart
  
  def index
    @order = Order.find_by(cart_key: cookies[:cart])
  end


  # GET /cart/add
  def add
    order = load_or_create_order
    
    # iterate through multiple items being added to cart
    # key = {product-id}-{affiliate-id}-{variation}
    params.each do |key, val|
      next unless key.include?('qty-')

      product_id = key.split("-").last
      quantity = val.to_i
      
      next unless quantity > 0
      p = Product.find(product_id)
      
      #check if item already exists
      item = order.items.find do |i| 
        i.product_id == product_id && 
        i.custom_text == params[:custom_text] &&
        i.uploaded_file == params[:uploaded_file] && 
        i.start_x_percent == params[:start_x_percent] &&
        i.start_y_percent == params[:start_y_percent] &&
        i.width_percent == params[:width_percent] &&
        i.height_percent == params[:height_percent]
      end
      
      if item.nil?

        item = OrderItem.new(order_id: order.id,
			                			product_id: product_id,
														item_number: p.item_number,
					                	quantity: quantity,
					                	quantity_accepted: quantity,
					                	unit_price: p.special_price || p.price,
					                	item_description: p.title,
					                	uploaded_file: params[:uploaded_file],
					                	start_x_percent: params[:start_x_percent],
					                	start_y_percent: params[:start_y_percent],
					                	width_percent: params[:width_percent],
					                	height_percent: params[:height_percent],
					                	custom_text: params[:custom_text],
					                	autoship_months: params[:autoship_months].blank? ? 0 : params[:autoship_months])

        order.items << item
        
        # create image preview if this is a personalized product
        PersonalizedLabelJob.perform_later(item.id, 'web') unless item.uploaded_file.nil?
      else
        item.quantity += quantity
        item.autoship_months = params[:autoship_months].blank? ? 0 : item.autoship_months
        item.save
      end
      
      flash[:item_id] = item.id   # Used by HSN personalization
    end
    
    update_totals order
    order.save validate: false

    respond_to do |format|
      format.html do 
        if params[:redirect].nil?
          redirect_to action: 'index'
        else
          redirect_to params[:redirect]
        end
      end
    	format.js { render layout: false }
		end
    
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
    item = order.items.find { |i| i.daily_deal_id == dd.id && i.custom_text == params[:order_specifications] }
    if item.nil?

      item = OrderItem.new order_id: order.id,
              daily_deal_id: dd.id,
              quantity: params[:qty],
              unit_price: dd.deal_price,
              item_description: dd.short_tag_line,
              item_number: "DEAL#{dd.id}",
              custom_text: params[:order_specifications]

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
    order.save(validate: false)
    
    respond_to do |format|
      format.html { redirect_to action: 'index' }
    	format.js { render layout: false }
		end
  end
  

  # GET /cart/apply_fb_discount?dd=
  def apply_fb_discount
    dd = DailyDeal.find(params[:dd])
    order = load_or_create_order
    order.fb_discount = dd.fb_discount
    order.save(validate: false)
    render json: { status: :ok }
  end


  def remove
    id = params[:id].to_i
    order = Order.includes(:items).find_by(cart_key: cookies[:cart]) unless cookies[:cart].nil?

    if order != nil
      item = order.items.find { |t| t.id == id }
      unless item.nil?
        order.items.destroy(item)

        # update order or delete altogether if no items left
        if order.items.length > 0
          update_totals(order)
          order.save(validate: false)
        else
          order.destroy
        end
      end
    end

    redirect_to :back
  end

  
  def update
    order = Order.includes(:items).find_by(cart_key: cookies[:cart]) unless cookies[:cart].nil?
    return redirect_to :back if order.nil?
    
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
          flash[:error] = "Sorry, #{item.item_number} is limited to #{item.daily_deal.max_per_user} per customer."
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
  
  # GET /cart/personalize?item=ITEM_NUMBER
  def personalize
    @product = Product.find_by!("item_number = ? OR upc = ?", params[:item], params[:item]) # check UPC because of FAV
    @order = load_or_create_order
  end
  
  # POST /cart/upload_picture
  def upload_picture
    file_path = Cache.setting(Rails.configuration.domain_id, "System", "Static Files Path")
    uploaded_io = params[:file]
    ext = uploaded_io.original_filename.split('.').last.downcase
    
    unless uploaded_io.nil? || ['jpg', 'jpeg', 'tiff', 'gif', 'bmp'].include?(ext) == false
      file_name = SecureRandom.hex(6) + '.' + ext
      file_path = file_path + '/uploads/' + file_name
     
      File.open(file_path, 'wb') do |file|
        file.write(uploaded_io.read)
      end
      
      order = load_or_create_order
      order.pictures.create(file_path: '/uploads/' + file_name, user_id: session[:user_id], caption: 'user upload') 
      
      return render json: { status: 'ok', file_path: '/uploads/' + file_name }
    end
    
    render json: { status: 'error', message: "Not a valid image file" }
  end
  
  def checkout
      @order = Order.includes(:items).find_by(cart_key: cookies[:cart]) unless cookies[:cart].nil?
      return redirect_to action: 'index' if (@order.nil? || @order.items.length == 0)
      
      # check if login is required
      if (session[:user_id].nil? && Cache.setting(Rails.configuration.domain_id, "eCommerce", "Checkout Require Login") == "true")
        flash[:notice] = "Please log in to proceed with checkout"
        return redirect_to "/login?redirect=/cart/checkout"
      end

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
    @order = Order.includes(:items).find_by(cart_key: cookies[:cart]) unless cookies[:cart].nil?
    return redirect_to action: 'index' if @order.nil? || @order.items.length == 0
    
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
    @order.create_user if @order.user_id.nil?

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

    begin
      # CHECK TO SEE IF THIS IS A DUPLCATE.  AT THIS POINT THERE SHOULD BE NO PAYMENTS
      raise "Duplicate order" if (@order.status == 'submitted' || @order.payments.count > 0)
      
      # PROCESS PAYMENT  (this method will save status,submitted fields to the database)
      @order.process_payment(request)
    rescue => e
      @order.errors.add :base, e.message
      return render "review"
    end
  
    # IMPORTANT:  save the order!
    @order.save validate: false
    
    # Do other stuff like deal counter updates, affiliate commission etc.
    WebOrderJob.perform_later(order_id: @order.id, 
                              email_blast_uuid: cookies[:ebuuid], 
                              referral_key: cookies[:refkey],
                              affiliate_campaign_id: cookies[:acid])
    
    # delete cart cookie and display confirmation
    cookies.delete :cart
    session[:order_id] = @order.id
    
    redirect_to action: 'submitted', id: @order.id
  end
  
  
  def submitted
    @order = Order.includes(:items).find(session[:order_id])
  end
  

  def applycode

    # load order
    applied = false
    order = Order.includes(:items).find_by(cart_key: cookies[:cart])
    
    if order.nil? || order.items.length == 0
      flash[:error] = "You don't have any items in your cart."
      return redirect_to :back
    end

    # test if code is a coupon code
    coupon = Coupon.find_by(code: params[:code])
    unless coupon.nil?

      applied = true
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
      :cc_code, :notify_email, :customer_note, :payment_method, :same_as_shipping, :user_id)
    end
  
end
