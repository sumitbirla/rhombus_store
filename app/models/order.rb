# == Schema Information
#
# Table name: orders
#
#  id                    :integer          not null, primary key
#  external_id           :string(255)
#  provider              :string(255)
#  user_id               :integer
#  cart_key              :string(255)
#  affiliate_campaign_id :integer
#  referred_by           :integer
#  coupon_id             :integer
#  voucher_id            :integer
#  combined              :boolean          default(FALSE), not null
#  gift                  :boolean          default(FALSE), not null
#  tax_amount            :decimal(10, 2)   default(0.0), not null
#  tax_rate              :decimal(5, 2)    default(0.0), not null
#  shipping_cost         :decimal(6, 2)    default(0.0), not null
#  shipping_method       :string(255)
#  discount_amount       :decimal(10, 2)   default(0.0), not null
#  credit_applied        :decimal(10, 2)   default(0.0), not null
#  subtotal              :decimal(10, 2)   default(0.0), not null
#  total                 :decimal(10, 2)   default(0.0), not null
#  status                :string(255)      not null
#  submitted             :datetime
#  shipping_name         :string(255)
#  shipping_company      :string(255)
#  shipping_street1      :string(255)
#  shipping_street2      :string(255)
#  shipping_city         :string(255)
#  shipping_state        :string(255)
#  shipping_zip          :string(255)
#  shipping_country      :string(255)
#  billing_name          :string(255)
#  billing_company       :string(255)
#  billing_street1       :string(255)
#  billing_street2       :string(255)
#  billing_city          :string(255)
#  billing_state         :string(255)
#  billing_zip           :string(255)
#  billing_country       :string(255)
#  customer_note         :text
#  notify_email          :string(255)
#  contact_phone         :string(255)
#  payment_method        :string(255)      default(""), not null
#  cc_type               :string(255)
#  cc_number             :string(255)
#  cc_code               :string(255)
#  cc_expiration_month   :integer
#  cc_expiration_year    :integer
#  paypal_token          :string(255)
#  paypal_payer_id       :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

require 'activemerchant'

class Order < ActiveRecord::Base
  include PaypalExpressHelper
  
  self.table_name = "store_orders"
  attr_accessor :same_as_shipping
  
  belongs_to :domain
  belongs_to :user
  belongs_to :affiliate_campaign
  belongs_to :coupon
  belongs_to :voucher
  
  has_many :items, class_name: 'OrderItem'
  has_many :history, class_name: 'OrderHistory'
  has_many :shipments
  has_many :payments, as: :payable
  
  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: lambda { |attrs| attrs['product_id'].blank? && attrs['daily_deal_id'].blank?}
  
  validates_presence_of :shipping_name, :shipping_street1, :shipping_city, :shipping_state, :shipping_zip, :shipping_country
  validates_presence_of :contact_phone, :notify_email
  validates_presence_of :billing_name, :billing_street1, :billing_city, :billing_state, :billing_zip, :billing_country, if: :billing_address_required?
  validates_presence_of :cc_type, :cc_number, :cc_expiration_month, :cc_expiration_year, :cc_code, if: :paid_with_card?
  validate :credit_card, if: :paid_with_card?
  
  def deal_items
    items.select { |x| x.daily_deal_id != nil }
  end
  
  def non_deal_items
    items.select { |x| x.daily_deal_id.nil? }
  end
  
  def self.to_csv
    CSV.generate do |csv|
      cols = column_names - ['paypal_token', 'cart_key']
      csv << cols
      all.each do |product|
        csv << product.attributes.values_at(*cols)
      end
    end
  end
  
  def paid_with_card?
    payment_method == "CREDIT_CARD"
  end
  
  def billing_address_required?
    same_as_shipping == '0' && paid_with_card?
  end
  
  def credit_card
    
    credit_card = ActiveMerchant::Billing::CreditCard.new(
      :brand              => cc_type,
      :number             => cc_number,
      :verification_value => cc_code,
      :month              => cc_expiration_month,
      :year               => cc_expiration_year,
      :first_name         => billing_name.split[0],
      :last_name          => billing_name.split[1]
    )
    
    unless credit_card.valid?
      errors.add(:cc_number, "Credit card is not valid. #{credit_card.errors.full_messages.join('. ')}")
    end
    
    credit_card
  end
  
  def copy_shipping_address
    self.billing_name = shipping_name
    self.billing_street1 = shipping_street1
    self.billing_street2 = shipping_street2
    self.billing_city = shipping_city
    self.billing_state = shipping_state
    self.billing_zip = shipping_zip
    self.billing_country = shipping_country
  end
  
  def total_cents
    (total * 100.0).to_i
  end
  
  def self.valid_statuses
    [ 'submitted', 'completed', 'unshipped', 'shipped', 'refunded', 'cancelled', 'backordered' ]
  end
  
  # create a dummy user if one doesn't exist and assign user_id.  user object is not saved
  def create_user
    return unless user_id.nil?
    
    u = User.find_by(email: notify_email, domain_id: domain_id)
    if u.nil?
      u = User.create(
            name: shipping_name || "unknown",
            email: notify_email,
            phone: contact_phone,
            status: "Z",
            role_id: Role.find_by(default: true).id,
            domain_id: domain_id,
            password_digest: SecureRandom.hex(8),
            referral_key: SecureRandom.hex(5),
            location: "#{shipping_city}, #{shipping_state}")
    end
    
    self.user_id = u.id
  end
  
  
  # process payment, this is called when order is being submitted on website
  def process_payment(request)
    if payment_method == 'PAYPAL'

      gateway = ActiveMerchant::Billing::PaypalExpressGateway.new(
          :login => Cache.setting(domain_id, 'eCommerce', 'PayPal API Username'),
          :password => Cache.setting(domain_id, 'eCommerce', 'PayPal API Password'),
          :signature => Cache.setting(domain_id, 'eCommerce', 'PayPal Signature'),
      )

      total_as_cents, purchase_params = get_purchase_params(self, request)
      response = gateway.purchase(total_as_cents, purchase_params)

      raise "PayPal processing failed: #{response.message}" unless response.success?

      self.status = 'submitted'
      self.submitted = Time.now
      
      Payment.create(payable_id: id, payable_type: :order, amount: total, memo: 'PayPal Payment', 
                     user_id: user_id, transaction_id: response.authorization)

      # add order history row
      OrderHistory.create order_id: id, user_id: user_id, amount: total,
                          event_type: 'paypal_payment', system_name: 'PayPal', identifier: response.authorization,
                          comment: notify_email

    elsif payment_method == "CREDIT_CARD"
      
      active_gw = Cache.setting(domain_id, 'eCommerce', 'Payment Gateway')

      if active_gw == 'Authorize.net'
        gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(
            :login => Cache.setting(domain_id, 'eCommerce', 'Authorize.Net Login ID'),
            :password => Cache.setting(domain_id, 'eCommerce', 'Authorize.Net Transaction Key'),
            :test => false
        )
      elsif active_gw == 'Stripe'
        gateway = ActiveMerchant::Billing::StripeGateway.new(
            :login => Cache.setting(domain_id, 'eCommerce', 'Stripe Secret Key')
        )  
      else
        raise "Payment gateway is not set up."
      end 

      customer_name = billing_name
      customer_name = user.name unless user_id.nil?
      
      purchase_options = {
        :ip => request.remote_ip,
        :order_id => id,
        :customer => customer_name,
        :billing_address => {
          :name     => billing_name,
          :address1 => billing_street1,
          :city     => billing_street2,
          :state    => billing_state,
          :zip      => billing_zip
      }}

      response = gateway.purchase(total_cents, credit_card, purchase_options)

      # credit cart authorization failed?
      raise response.message unless response.success?
      
      # save CC?
      if items.any? { |x| x.autoship_months > 0 }
        unless PaymentMethod.exists?(user_id: user_id, card_display: "x-#{cc_number.last(4)}")
          PaymentMethod.create(
                    user_id: user_id,
                    default: true,
                    cardholder_name: billing_name,
                    number: cc_number,
                    expiration_month: cc_expiration_month,
                    expiration_year: cc_expiration_year,
                    billing_street1: billing_street1,
                    billing_street2: billing_street2,
                    billing_city: billing_city,
                    billing_state: billing_state,
                    billing_zip: billing_zip,
                    billing_country: billing_country,
                    status: "A",
                    last_transaction_date: DateTime.now,
                    last_transaction_result: response.message)
          end
      end
  
      self.status = 'submitted'
      self.submitted = Time.now
      self.cc_code = nil
      self.cc_number = credit_card.display_number

      Payment.create(payable_id: id, payable_type: :order, amount: total, memo: cc_number, 
                    user_id: user_id, transaction_id: response.authorization)
      
      # add order history row
      OrderHistory.create order_id: id, user_id: user_id, amount: total,
                          event_type: 'cc_authorization', system_name: active_gw, identifier: response.authorization,
                          comment: "Successfully charged #{cc_number}"

    else # NO_BILLING
      self.status = 'submitted'
      self.submitted = Time.now
    end
    
  end
  
  
  
  # create shipment for the order.  doesn't take inventory into consideration currently
  def create_shipment(user_id)
    seq = 1
    max_seq = shipments.maximum(:sequence)
    seq = max_seq + 1 unless max_seq.nil?

    shipment = Shipment.new(order_id: id,
                             sequence: seq,
                             recipient_company: shipping_company,
                             recipient_name: shipping_name,
                             recipient_street1: shipping_street1,
                             recipient_street2: shipping_street2,
                             recipient_city: shipping_city,
                             recipient_state: shipping_state,
                             recipient_zip: shipping_zip,
                             recipient_country: shipping_country,
                             package_weight: 1.0,
                             status: 'pending')

     loc_id = Cache.setting(shipment.order.domain_id, :shipping, "Ship From Location ID")
     loc = Location.find(loc_id) if loc_id

     unless loc.nil?
       shipment.assign_attributes(ship_from_company: loc.name,
                                   ship_from_street1: loc.street1,
                                   ship_from_street2: loc.street2,
                                   ship_from_city: loc.city,
                                   ship_from_state: loc.state,
                                   ship_from_zip: loc.zip,
                                   ship_from_country: loc.country,
                                   ship_from_email: loc.email,
                                   ship_from_phone: loc.phone)
    end 
    
    # set invoice amount
    shipment.invoice_amount = shipment.order.total if seq == 1
    
    # build the shipment items                
    items.each do |item|
      
      # regular order item, not a daily deal
      if item.product_id
        shipment.items.build(order_item_id: item.id, 
                             product_id: item.product_id,
                             affiliate_id: item.affiliate_id,
                             variation: item.variation, 
                             quantity: item.quantity)

      elsif item.daily_deal_id
        item.daily_deal.items.each do |di|
          shipment.items.build(order_item_id: item.id, 
                               product_id: di.product_id,
                               affiliate_id: di.affiliate_id,
                               variation: di.variation, 
                               quantity: item.quantity * di.quantity)
        end
      end

    end

    if shipment.save  
      OrderHistory.create(order_id: id, user_id: user_id, event_type: :shipment_created,
                    system_name: 'Rhombus', identifier: shipment.id, comment: "shipment created: #{shipment}") 
    end
    
    shipment
  end
  
  
  
  
  
end
