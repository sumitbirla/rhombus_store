require 'activemerchant'

class PaypalExpressController < ActionController::Base
  before_filter :assigns_gateway

  include ActiveMerchant::Billing
  include PaypalExpressHelper
  include CartHelper


  def checkout
    @cart = Order.includes(:items, [items: [:product]]).find_by(cart_key: cookies[:cart])

    total_as_cents, setup_purchase_params = get_setup_purchase_params @cart, request

    puts total_as_cents, setup_purchase_params

    setup_response = @gateway.setup_purchase(total_as_cents, setup_purchase_params)
    redirect_to @gateway.redirect_url_for(setup_response.token)
  end


  def review
    if params[:token].nil?
      flash[:error] =  'Woops! Something went wrong!'
      return redirect_to cart_path
    end

    gateway_response = @gateway.details_for(params[:token])

    unless gateway_response.success?
      flash[:error] = "Sorry! Something went wrong with the Paypal purchase. Here's what Paypal said: #{gateway_response.message}"
      return redirect_to cart_path
    end

    @cart = Order.find_by(cart_key: cookies[:cart])

    @cart.assign_attributes({
      notify_email: gateway_response.email,
      billing_name: gateway_response.name,
      shipping_name: gateway_response.address['name'],
      shipping_company: gateway_response.address['company'],
      shipping_street1: gateway_response.address['address1'],
      shipping_street2: gateway_response.address['address2'],
      shipping_city: gateway_response.address['city'],
      shipping_state: gateway_response.address['state'],
      shipping_zip: gateway_response.address['zip'],
      shipping_country: gateway_response.address['country'],
      payment_method: 'PAYPAL',
      paypal_token: gateway_response.token,
      paypal_payer_id: gateway_response.payer_id,
      sales_channel: Cache.setting(Module::Rails.configuration.domain_id, :system, 'Website Name')
    })
    
    update_totals(@cart)

    # check if there is a user associated with this email address
    if @cart.user_id.nil?
      user = User.find_by(email: gateway_response.email)
      @cart.user_id = user.id unless user.nil?
    end

    @cart.save(validate: false)
    redirect_to controller: 'cart', action: 'review'
  end


  private

    def assigns_gateway
      @gateway ||= PaypalExpressGateway.new(
          :login => Cache.setting(Module::Rails.configuration.domain_id, 'eCommerce', 'PayPal API Username'),
          :password => Cache.setting(Module::Rails.configuration.domain_id, 'eCommerce', 'PayPal API Password'),
          :signature => Cache.setting(Module::Rails.configuration.domain_id, 'eCommerce', 'PayPal Signature'),
      )
    end
end