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
#  created_at           :datetime
#  updated_at           :datetime
#  manifest_id          :integer
#  third_party_billing  :boolean          default(FALSE), not null
#

require 'net/http'
require 'uri'
require 'digest/md5'

class Shipment < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_shipments"

  before_save :update_items_hash
  after_save :update_order
  after_create :save_inventory_transaction, unless: :skip_inventory
  
  belongs_to :order
  belongs_to :fulfiller, class_name: 'User', foreign_key: 'fulfilled_by_id'
  has_many :items, class_name: 'ShipmentItem', dependent: :destroy
  has_one :inventory_transaction, dependent: :destroy
  has_many :logs, as: :loggable
  
  accepts_nested_attributes_for :items, allow_destroy: true

  validates_presence_of :ship_from_company, :ship_from_street1, :ship_from_city, :ship_from_state, :ship_from_zip, :ship_from_country
  validates_presence_of :recipient_name, :recipient_street1, :recipient_city, :recipient_zip, :recipient_country
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
  
  def post_invoice
    return if (invoice_amount == 0.0 || invoice_posted?)
    Payment.create(user_id: order.user_id, payable_id: id, payable_type: :shipment, amount: invoice_amount * -1.0, memo: 'invoice')               
  end
  
  # this callback is executed after shipment is saved
  def update_order
    if status == "shipped"
      if Shipment.where(order_id: order_id).where.not(status: "shipped").length == 0
        Order.find(order_id).update_attribute(:status, "shipped")
      end
    end
    
    if status == "pending"
      Order.find(order_id).update_attribute(:status, "awaiting_shipment")
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
    tran.shipment_id = id
    tran.save
  end
  
  # creates a new transaction without saving to DB
  def new_inventory_transaction
    tran = InventoryTransaction.new
    products = Product.where(id: items.map(&:product_id).uniq).select(:id, :sku)
    
    products.each do |p|
      quantity = items.select { |x| x.product_id == p.id }.sum(&:quantity)
      tran.items << InventoryItem.get(p.sku, quantity)
    end
    
    tran
  end
  
  def items_hash
    str = ""
    product_ids = items.collect(&:product_id).uniq.sort
    
    product_ids.each do |pid|
      quantity = items.select { |x| x.product_id == pid }.sum(&:quantity)
      str << "#{pid}:#{quantity}|"
    end
    
    md5 = Digest::MD5.new
    md5.hexdigest(str)
  end
  
  def update_items_hash
    self.items_hash = items_hash
  end
  
end
