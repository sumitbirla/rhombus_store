# == Schema Information
#
# Table name: store_orders
#
#  id                     :integer          not null, primary key
#  batch_id               :integer
#  domain_id              :integer          not null
#  external_order_id      :string(255)
#  sales_channel          :string(255)
#  user_id                :integer
#  affiliate_id           :integer
#  financial_status       :string(255)
#  fulfillment_status     :string(255)
#  cart_key               :string(255)      default(""), not null
#  affiliate_campaign_id  :integer
#  referred_by            :integer
#  coupon_id              :integer
#  voucher_id             :integer
#  combined               :boolean          default(FALSE), not null
#  gift                   :boolean          default(FALSE), not null
#  auto_ship              :boolean          default(FALSE), not null
#  tax_amount             :decimal(10, 2)   default(0.0), not null
#  tax_rate               :decimal(5, 2)    default(0.0), not null
#  shipping_cost          :decimal(6, 2)    default(0.0), not null
#  shipping_method        :string(255)
#  discount_amount        :decimal(10, 2)   default(0.0), not null
#  credit_applied         :decimal(10, 2)   default(0.0), not null
#  subtotal               :decimal(10, 2)   default(0.0), not null
#  total                  :decimal(10, 2)   default(0.0), not null
#  status                 :string(255)      not null
#  submitted              :datetime
#  shipping_name          :string(255)
#  shipping_company       :string(255)
#  shipping_street1       :string(255)
#  shipping_street2       :string(255)
#  shipping_city          :string(255)
#  shipping_state         :string(255)
#  shipping_zip           :string(255)
#  shipping_country       :string(255)
#  billing_name           :string(255)
#  billing_company        :string(255)
#  billing_street1        :string(255)
#  billing_street2        :string(255)
#  billing_city           :string(255)
#  billing_state          :string(255)
#  billing_zip            :string(255)
#  billing_country        :string(255)
#  customer_note          :text(65535)
#  notify_email           :string(255)
#  contact_phone          :string(255)
#  payment_due            :date
#  payment_method         :string(255)      default("")
#  po                     :boolean          default(FALSE), not null
#  allow_backorder        :boolean          default(FALSE), not null
#  ship_earliest          :date
#  ship_latest            :date
#  cc_type                :string(255)
#  cc_number              :string(255)
#  cc_code                :string(255)
#  cc_expiration_month    :integer
#  cc_expiration_year     :integer
#  paypal_token           :string(255)
#  paypal_payer_id        :string(255)
#  fb_discount            :decimal(5, 2)    default(0.0), not null
#  expected_delivery_date :date
#  created_at             :datetime
#  updated_at             :datetime
#


## FINANCIAL STATUS:   pending, authorized, partially_paid, paid, partially_refunded, refunded, voided
## FULFILLMENT STATUS: fulfilled, nil, partial, restocked

require 'activemerchant'

class Order < ActiveRecord::Base
  include PaypalExpressHelper
  include PaymentGateway
  include Exportable
  
  self.table_name = "store_orders"
  attr_accessor :same_as_shipping
  
  belongs_to :domain
	# belongs_to :sales_channel
  belongs_to :user
  belongs_to :affiliate
  belongs_to :affiliate_campaign
  belongs_to :coupon
  belongs_to :voucher
  belongs_to :batch
  
  # destroy with super-caution because the following items will also be deleted
  has_many :items, class_name: 'OrderItem', dependent: :destroy
  has_many :history, class_name: 'OrderHistory', dependent: :destroy
  has_many :shipments, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :payments, as: :payable, dependent: :destroy
  has_many :logs, as: :loggable, dependent: :destroy
  has_many :pictures, -> { order :sort }, as: :imageable, dependent: :destroy  # used for product personalization
  
  accepts_nested_attributes_for :items, reject_if: lambda { |x| x['product_id'].blank? && x['daily_deal_id'].blank?}, allow_destroy: true
  
  validates_presence_of :shipping_name, :shipping_street1, :shipping_city, :shipping_state, :shipping_zip, :shipping_country
  validates_presence_of :contact_phone, :notify_email
  validates_presence_of :billing_name, :billing_street1, :billing_city, :billing_state, :billing_zip, :billing_country, if: :billing_address_required?
  validates_presence_of :cc_type, :cc_number, :cc_expiration_month, :cc_expiration_year, :cc_code, if: :paid_with_card?
  validates_presence_of :affiliate_id, :external_order_id, if: :po
  validate :credit_card, if: :paid_with_card?
  
  def deal_items
    items.select { |x| x.daily_deal_id != nil }
  end
  
  def non_deal_items
    items.select { |x| x.daily_deal_id.nil? }
  end
  
  def paid_with_card?
    payment_method == "CREDIT_CARD"
  end
  
  def total_items
    items.map(&:quantity).sum
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
    [ 'accepted', 'backordered', 'cancelled', 'partially_shipped', 'shipped', 'submitted', 'awaiting_shipment' ]
  end
  
  # create a dummy user if one doesn't exist and assign user_id
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

      self.update_columns(status: 'submitted', submitted: Time.now, received: Time.now)
      
      Payment.create(payable_id: id, payable_type: :order, amount: total, memo: 'PayPal Payment', 
                     user_id: user_id, transaction_id: response.authorization)

      # add order history row
      OrderHistory.create order_id: id, user_id: user_id, amount: total,
                          event_type: 'paypal_payment', system_name: 'PayPal', identifier: response.authorization,
                          comment: notify_email

    elsif payment_method == "CREDIT_CARD"

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

      # active_gateway is defined in billing/models/concerns
      response = active_gateway(domain_id).purchase(total_cents, credit_card, purchase_options)

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
      
      self.update_columns(status: 'submitted', 
													submitted: Time.now, 
													received: Time.now, 
													cc_code: nil, 
													cc_number: credit_card.display_number)
  
      Payment.create(payable_id: id, payable_type: :order, amount: total, memo: cc_number, 
                    user_id: user_id, transaction_id: response.authorization)
      
      # add order history row
      OrderHistory.create order_id: id, user_id: user_id, amount: total,
                          event_type: 'cc_authorization', system_name: :active_merchant, identifier: response.authorization,
                          comment: "Successfully charged #{cc_number}"

    else # NO_BILLING
      self.update_columns(status: 'submitted', submitted: Time.now)
    end
    
  end
  
  # create shipment for the order.  doesn't take inventory into consideration currently
  def create_fulfillment(fulfiller_id, user_id, save_to_db = true)
    
    raise "There are no items in this order" if total_items == 0
    
    seq = 1
    max_seq = shipments.maximum(:sequence)
    seq = max_seq + 1 unless max_seq.nil?
		
		aff = Affiliate.find(fulfiller_id)

    shipment = Shipment.new(order_id: id,
                            fulfilled_by_id: fulfiller_id,
                            sequence: seq,
														ship_from_company: aff.name,
                            ship_from_street1: aff.street1,
                            ship_from_street2: aff.street2,
                            ship_from_city: aff.city,
                            ship_from_state: aff.state,
                            ship_from_zip: aff.zip,
                            ship_from_country: aff.country,
                            ship_from_email: aff.email,
                            ship_from_phone: aff.phone,
                            recipient_company: shipping_company,
                            recipient_name: shipping_name,
                            recipient_street1: shipping_street1,
                            recipient_street2: shipping_street2,
                            recipient_city: shipping_city,
                            recipient_state: shipping_state,
                            recipient_zip: shipping_zip,
                            recipient_country: shipping_country,
                            status: 'pending')

    # build the shipment items                
    items.each do |item|
      
      # regular order item, not a daily deal
      if item.product_id
        next if item.product.fulfiller_id != aff.id
        
        shipment.items.build(order_item_id: item.id,
                             quantity: item.quantity_accepted - item.quantity_shipped)

      elsif item.daily_deal_id
        
        if item.custom_text.blank?  
          item.daily_deal.items.each do |di|
            shipment.items.build(order_item_id: item.id,
                               quantity: item.quantity * di.quantity)
          end
        else
          # user may have selected a specific item from drowndown
          p = Product.find_by(item_number: item.custom_text.split(":").first)
          shipment.items.build(order_item_id: item.id, quantity: item.quantity)
        end
        
      end

    end
    
    if save_to_db && shipment.save! 
      OrderHistory.create(order_id: id, user_id: user_id, event_type: :shipment_created,
                    system_name: 'Rhombus', identifier: shipment.id, comment: "shipment created: #{shipment}") 
    end
    
    shipment
  end
  
  
  # create shipment for the order.  doesn't take inventory into consideration currently
  def create_shipment(user_id, save_to_db = true)
    
    raise "There are no items in this order" if total_items == 0
    
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
                             status: 'pending')

     loc_id = Cache.setting(domain_id, :shipping, "Ship From Location ID")
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
    # shipment.invoice_amount = shipment.order.total if seq == 1
    
    # build the shipment items                
    items.each do |item|
      
      # regular order item, not a daily deal
      if item.product_id
        shipment.items.build(order_item_id: item.id,
                             quantity: item.quantity_accepted - item.quantity_shipped)

      elsif item.daily_deal_id
        
        if item.custom_text.blank?  
          item.daily_deal.items.each do |di|
            shipment.items.build(order_item_id: item.id,
                               quantity: item.quantity * di.quantity)
          end
        else
          # user may have selected a specific item from drowndown
          p = Product.find_by(item_number: item.custom_text.split(":").first)
          shipment.items.build(order_item_id: item.id, quantity: item.quantity)
        end
        
      end

    end
    
    if save_to_db && shipment.save! 
      OrderHistory.create(order_id: id, user_id: user_id, event_type: :shipment_created,
                    system_name: 'Rhombus', identifier: shipment.id, comment: "shipment created: #{shipment}") 
    end
    
    shipment
  end
  
  # when an affiliate places a PO,  this method updates the store_affiliate_product listings with 
  # prices specified on this order.   New entries created if they don't already exist.
  def update_price_list
    
    items.each do |i|
      ap = AffiliateProduct.find_or_initialize_by(affiliate_id: affiliate_id, product_id: i.product_id)
      ap.price = i.unit_price
      ap.save
    end
    
  end
  
  # check to see if shipments (status 'shipped') contain all items orders
  def complete_order_shipped?
    shipped_items = ShipmentItem.joins(:shipment)
                                .where("store_shipments.order_id = ? AND store_shipments.status = 'shipped'", id)
    
    items.each do |i|
      if i.quantity > shipped_items.select{ |x| x.order_item_id == i.id }.sum(&:quantity)
        return false
      end
    end
    
    true
  end
  
  
  def shipment_created?(fulfiller_id)
    shipped_items = ShipmentItem.joins(:shipment, [order_item: :product])
                                .where("store_shipments.order_id = ?", id)
                                .where("store_products.fulfiller_id = ?", fulfiller_id)
                                
    items.each do |i|
      next if i.product.fulfiller_id != fulfiller_id
      return false if i.quantity > shipped_items.select{ |x| x.order_item_id == i.id }.sum(&:quantity)
    end
  end
  
  
  def fulfillers
    fulfillers = items.joins(:product)
                      .group("store_products.fulfiller_id")
                      .pluck("store_products.fulfiller_id")
                      
    Affiliate.where(id: fulfillers)
  end
  
  
  def estimated_shipping_weight
    weight = 0.0
    items.each do |i|
      weight += (i.product.item_weight.presence || 1.0) * i.quantity
    end
    weight * 1.15  #  account 15% for packaging
  end
  
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
  
end
