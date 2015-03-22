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
    billing_name = shipping_name
    billing_street1 = shipping_street1
    billing_street2 = shipping_street2
    billing_city = shipping_city
    billing_state = shipping_state
    billing_zip = shipping_zip
    billing_country = shipping_country
  end
  
  def total_cents
    (total * 100.0).to_i
  end
  
  def self.valid_statuses
    [ 'submitted', 'completed', 'unshipped', 'shipped', 'refunded', 'cancelled', 'backordered' ]
  end
  
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
                    
    if shipment.save
      weight = 0.3
      
      items.each do |item|
        shipment.items << ShipmentItem.new(shipment_id: shipment.id, order_item_id: item.id, quantity: item.quantity)
        weight += item.quantity * item.product.item_weight unless (item.product.nil? || item.product.item_weight.nil?)
      end
      
      shipment.update_attribute(:package_weight, weight) unless weight == 0.3
    end
    
    OrderHistory.create(order_id: id, user_id: user_id, event_type: :shipment_created,
                  system_name: 'Rhombus', identifier: shipment.id, comment: "shipment created: #{shipment}") 
    
    shipment
  end
  
end
