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

    @cart.notify_email = gateway_response.email
    @cart.billing_name = gateway_response.name
    @cart.shipping_name = gateway_response.address['name']
    @cart.shipping_company = gateway_response.address['company']
    @cart.shipping_street1 = gateway_response.address['address1']
    @cart.shipping_street2 = gateway_response.address['address2']
    @cart.shipping_city = gateway_response.address['city']
    @cart.shipping_state = gateway_response.address['state']
    @cart.shipping_zip = gateway_response.address['zip']
    @cart.shipping_country = gateway_response.address['country']

    @cart.payment_method = 'PAYPAL'
    @cart.paypal_token = gateway_response.token
    @cart.paypal_payer_id = gateway_response.payer_id
    @cart.sales_channel = 'PayPal'

    apply_shipping(@cart)
    apply_tax(@cart)
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
          :login => Cache.setting('eCommerce', 'PayPal API Username'),
          :password => Cache.setting('eCommerce', 'PayPal API Password'),
          :signature => Cache.setting('eCommerce', 'PayPal Signature'),
      )
    end
end