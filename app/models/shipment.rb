# == Schema Information
#
# Table name: store_shipments
#
#  id                   :integer          not null, primary key
#  order_id             :integer
#  sequence             :integer          not null
#  fulfilled_by_id      :integer
#  invoice_amount       :decimal(10, 2)   default(0.0), not null
#  status               :string(255)      not null
#  ship_from_company    :string(255)      default(""), not null
#  ship_from_street1    :string(255)      default(""), not null
#  ship_from_street2    :string(255)
#  ship_from_city       :string(255)      default(""), not null
#  ship_from_state      :string(255)      default(""), not null
#  ship_from_zip        :string(255)      default(""), not null
#  ship_from_country    :string(255)      default(""), not null
#  ship_from_email      :string(255)
#  ship_from_phone      :string(255)
#  recipient_name       :string(255)      not null
#  recipient_company    :string(255)
#  recipient_street1    :string(255)      not null
#  recipient_street2    :string(255)
#  recipient_city       :string(255)      not null
#  recipient_state      :string(255)
#  recipient_zip        :string(255)      not null
#  recipient_country    :string(255)      not null
#  carrier              :string(255)
#  ship_method          :string(255)
#  tracking_number      :string(255)
#  ship_date            :date
#  ship_cost            :decimal(6, 2)
#  package_length       :decimal(6, 2)
#  package_width        :decimal(6, 2)
#  package_height       :decimal(6, 2)
#  package_weight       :decimal(6, 2)
#  notes                :text(65535)
#  packaging_type       :string(255)
#  require_signature    :boolean
#  insurance            :decimal(8, 2)    default(0.0), not null
#  drop_off_type        :string(255)
#  label_data           :binary(16777215)
#  label_format         :string(255)
#  courier_name         :string(255)
#  courier_data         :text(16777215)
#  fulfiller_notified   :boolean          default(FALSE), not null
#  inventory_updated    :boolean          default(FALSE), not null
#  batch_status         :string(255)
#  batch_status_message :string(255)
#  manifest_id          :integer
#  third_party_billing  :boolean          default(FALSE), not null
#  items_hash           :string(32)
#  created_at           :datetime
#  updated_at           :datetime
#

require 'net/http'
require 'uri'
require 'digest/md5'
require 'business_time'

class Shipment < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_shipments"

  before_save :update_items_hash, :set_uuid
  after_save :update_order
  after_create :save_inventory_transaction, unless: :skip_inventory
  
  belongs_to :order
  belongs_to :fulfiller, class_name: 'Affiliate', foreign_key: 'fulfilled_by_id'
  
  has_many :items, class_name: 'ShipmentItem', dependent: :destroy
  has_many :packages, class_name: 'ShipmentPackage', dependent: :destroy
  has_many :logs, as: :loggable
  has_many :payments, as: :payable
  has_one :inventory_transaction, foreign_key: :external_id, primary_key: :uuid, dependent: :destroy
  
  accepts_nested_attributes_for :items, allow_destroy: true
  accepts_nested_attributes_for :packages, allow_destroy: true

  validates_presence_of :ship_from_company, :ship_from_street1, :ship_from_city, :ship_from_state, :ship_from_zip, :ship_from_country
  validates_presence_of :recipient_name, :recipient_street1, :recipient_city, :recipient_zip, :recipient_country, :fulfilled_by_id
  validates_presence_of :ship_date, unless: Proc.new { |s| s.tracking_number.blank? }
  validate :sufficient_inventory?, unless: Proc.new { |s| s.persisted? || s.skip_inventory }
  #validates_presence_of :package_weight
  
  def skip_inventory
    @skip_inventory
  end
  
  def skip_inventory=(str)
    @skip_inventory = (str == "1")
  end
  

  def dimensions_available?
    !(package_length.nil? || package_width.nil? || package_height.nil?)
  end

  def to_s
    "#{order_id}-#{sequence}"
  end
	
	def set_uuid
		self.uuid = Rails.configuration.system_prefix + "_shp_" + "#{order_id}_#{sequence}" if uuid.blank?
	end
  
  def calculate_invoice_amount
    subtotal = 0
    items.each { |item| subtotal += item.quantity * item.order_item.unit_price }
    subtotal
  end
  
  def invoice_posted?
    Payment.exists?(payable_type: :shipment, payable_id: id)
  end
  
  def same_content?(shipment)
    return false if shipment.items.length != items.length
    
    shipment.items.each do |i|
      if !items.any? { |x| x.product_id == i.product_id && x.quantity == i.quantity }
        return false
      end
    end
    
    true
  end
  
  def similar_shipment
    Shipment.where(status: :shipped, items_hash: items_hash)
            .where("ship_date > ?", 3.months.ago)
            .where.not(package_weight: nil)
            .order(ship_date: :desc)
            .first
  end
  
  
  # this callback is executed after shipment is saved
  def update_order
    statuses = Shipment.where(order_id: order_id).distinct(:status).pluck(:status)
    
    if statuses == [ "shipped" ] || statuses == [ "cancelled" ]
      Order.where(id: order_id).update_all(status: statuses[0])
    elsif statuses.include?("shipped")
      Order.where(id: order_id).update_all(status: "partially_shipped")
    end
  end
  
  def copy_easy_post(response)
    # save shipment object
    parcel = response[:parcel]
		from = response[:from_address]
		to = response[:to_address]
    plabel = response[:postage_label]
    rate = response[:selected_rate]
    
    self.assign_attributes(
      courier_name: 'EasyPost',

			ship_from_company: from[:company],
    	ship_from_street1: from[:street1],
    	ship_from_street2: from[:street2],
    	ship_from_city: from[:city],
    	ship_from_state: from[:state],
    	ship_from_zip: from[:zip],
    	ship_from_country: from[:country],

    	recipient_name: to[:name],
    	recipient_company: to[:company],
    	recipient_street1: to[:street1],
    	recipient_street2: to[:street2],
    	recipient_city: to[:city],
    	recipient_state: to[:state],
    	recipient_zip: to[:zip],
    	recipient_country: to[:country],
      
			packaging_type: parcel[:predefined_package] || 'YOUR PACKAGING',
    	package_width: parcel[:width],
    	package_length: parcel[:length],
    	package_height: parcel[:height],
    	package_weight: parcel[:weight] / 16.0
    )
    
    unless plabel.nil?
      # try to download label PNG
      label_url = plabel[:label_url]
      label_data = label_url
      begin
        label_data = Net::HTTP.get(URI.parse(label_url))
      rescue => e
      end
      
      self.assign_attributes(
        ship_date: DateTime.iso8601(plabel[:label_date]).to_date,
      	carrier: rate[:carrier],
        ship_method: rate[:service],
        ship_cost: rate[:rate],
        require_signature: response[:options][:delivery_confirmation] == 'SIGNATURE',
      	tracking_number: response[:tracking_code],
      	label_format: plabel[:label_file_type],
      	label_data: label_data,
      	courier_data: response.to_json    	
      )
    end
    
  end
  
  
  # INVENTORY METHODS
  
  # standard model validation for shipment
  def sufficient_inventory?
    begin
      new_inventory_transaction
    rescue => e
      errors.add(:base, e.message)
    end
  end
  
  # called by after_create filter
  def save_inventory_transaction
    tran = new_inventory_transaction
    tran.external_id = uuid
		tran.affiliate_id = fulfilled_by_id
    tran.save
  end
  
  # creates a new transaction without saving to DB
  def new_inventory_transaction
    tran = InventoryTransaction.new
		skus = Product.where(id: items.map(&:order_item).map(&:product_id)).pluck(:sku).uniq
    
    skus.each do |sku|
      quantity = items.select { |x| x.order_item.product.sku == sku }.sum(&:quantity)
      tran.items << InventoryItem.get(sku, quantity) unless quantity == 0
    end
    
    tran
  end
  
  def calculate_items_hash
    str = ""
		skus = Product.where(id: items.map(&:order_item).map(&:product_id)).pluck(:sku).uniq.sort
    
    skus.each do |sku|
      quantity = items.select { |x| x.order_item.product.sku == sku }.sum(&:quantity)
      str << "#{sku}:#{quantity}|"
    end
    
    md5 = Digest::MD5.new
    md5.hexdigest(str)
  end
  
  def update_items_hash
    self.items_hash = calculate_items_hash
  end
  
  # get shipment cost based on store_product_shipping_rates table
  def calculate_shipping_cost
    rates = {}  # hash of shipping_code : number_of_items
    cost = 0.00
    
    items.each do |i|
      code = i.order_item.product.shipping_code
      raise "Shipping code not set for #{i.order_item.product.item_number}" if code.blank?
      
      rates[code] = 0 if rates[code].nil?
      rates[code] += i.quantity
    end
    
    rates.each do |code, quantity|
      sr = ProductShippingRate.find_by!(code: code, destination_country_code: 'US', ship_method: :standard)
      cost += sr.get_cost(quantity)
    end
    
    cost
  end
	
	def calculated_weight
		weight = 0.0
		items.each do |si|
			raise "Item weight not set for #{si.order_item.item_number}" if si.order_item.product.item_weight.nil?
			weight += si.order_item.product.item_weight * si.quantity
		end
		weight * 1.1  # account for packaging materials
	end
  
  def affiliate_shipping_available?
    order.affiliate && order.affiliate.get_property("Use EasyPost") == "true"
  end
  
  def easy_post_api_key
    if affiliate_shipping_account
      key = order.affiliate.get_property("EasyPost API Key")
    else
      key = Cache.setting(order.domain_id, :shipping, 'EasyPost API Key')
    end
    
    raise "EasyPost API Key is not set." if key.blank?
    key
  end
  
  def is_late?
    if fulfilled_by_id and ['pending', 'transmitted'].include?(status)
    
      items.each do |si|
        ap = AffiliateProduct.find_by(affiliate_id: fulfilled_by_id, product_id: si.order_item.product_id)
        raise ("Dropshipper listing not found for #{si.order_item.item_number}") if ap.nil?
        
        return true if ap.ship_lead_time.business_days.after(order.submitted) < DateTime.now 
      end
      
    end
    
    false
  end
  
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
  
end
