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

class Shipment < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_shipments"
  after_save :update_order
  
  belongs_to :order
  belongs_to :fulfiller, class_name: 'User', foreign_key: 'fulfilled_by_id'
  has_many :items, class_name: 'ShipmentItem', dependent: :destroy
  has_many :invoices, as: :invoiceable
  has_one :inventory_transaction
  
  accepts_nested_attributes_for :items, allow_destroy: true

  validates_presence_of :ship_from_company, :ship_from_street1, :ship_from_city, :ship_from_state, :ship_from_zip, :ship_from_country
  validates_presence_of :recipient_name, :recipient_street1, :recipient_city, :recipient_zip, :recipient_country
  #validates_presence_of :package_weight
  

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
  
  
  def create_inventory_transaction(user_id = nil)
    tran = InventoryTransaction.new(shipment_id: id, user_id: user_id)
    products = items.group(:product_id).sum(:quantity)
    
    products.each do |product_id, quantity|  
      p = Product.find(product_id)
      tran.items << InventoryItem.get(p.sku, quantity)
    end
    
    tran
  end
  
end
