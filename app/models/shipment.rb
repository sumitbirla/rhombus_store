# == Schema Information
#
# Table name: store_shipments
#
#  id                         :integer          not null, primary key
#  affiliate_shipping_account :boolean          default(FALSE), not null
#  batch_status               :string(255)
#  batch_status_message       :string(255)
#  billing_processed          :boolean          default(FALSE), not null
#  carrier                    :string(255)
#  courier_data               :text(16777215)
#  courier_name               :string(255)
#  drop_off_type              :string(255)
#  external_name              :string(255)
#  fulfiller_notified         :boolean          default(FALSE), not null
#  insurance                  :decimal(8, 2)    default(0.0), not null
#  inventory_updated          :boolean          default(FALSE), not null
#  invoice_amount             :decimal(10, 2)
#  items_hash                 :string(32)
#  label_data                 :binary(16777215)
#  label_format               :string(255)
#  notes                      :text(65535)
#  package_height             :decimal(6, 2)
#  package_length             :decimal(6, 2)
#  package_weight             :decimal(6, 2)
#  package_width              :decimal(6, 2)
#  packaging_type             :string(255)
#  paid                       :boolean          default(FALSE), not null
#  recipient_city             :string(255)      not null
#  recipient_company          :string(255)
#  recipient_country          :string(255)      not null
#  recipient_name             :string(255)      not null
#  recipient_state            :string(255)
#  recipient_street1          :string(255)      not null
#  recipient_street2          :string(255)
#  recipient_zip              :string(255)      not null
#  require_signature          :boolean
#  seller_cogs                :decimal(10, 2)
#  seller_shipping_fee        :decimal(10, 2)
#  seller_transaction_fee     :decimal(10, 2)
#  sequence                   :integer          not null
#  ship_cost                  :decimal(6, 2)
#  ship_date                  :date
#  ship_from_city             :string(255)      default(""), not null
#  ship_from_company          :string(255)      default(""), not null
#  ship_from_country          :string(255)      default(""), not null
#  ship_from_email            :string(255)
#  ship_from_name             :string(255)
#  ship_from_phone            :string(255)
#  ship_from_state            :string(255)      default(""), not null
#  ship_from_street1          :string(255)      default(""), not null
#  ship_from_street2          :string(255)
#  ship_from_zip              :string(255)      default(""), not null
#  ship_method                :string(255)
#  status                     :string(255)      not null
#  third_party_billing        :boolean          default(FALSE), not null
#  tracking_number            :string(255)
#  tracking_uploaded_at       :datetime
#  uuid                       :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#  external_id                :string(255)
#  fulfilled_by_id            :integer          not null
#  manifest_id                :integer
#  order_id                   :integer
#
# Indexes
#
#  fulfilled_by_id              (fulfilled_by_id)
#  index_shipments_on_order_id  (order_id)
#  status                       (status)
#
# Foreign Keys
#
#  store_shipments_ibfk_1  (fulfilled_by_id => core_affiliates.id)
#

require 'net/http'
require 'uri'
require 'digest/md5'
require 'business_time'

class Shipment < ActiveRecord::Base
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
  validates_presence_of :ship_date, if: Proc.new { |s| s.status.downcase == "shipped" }
  #validate :sufficient_inventory?, unless: Proc.new { |s| s.persisted? || s.skip_inventory }
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


  def self.to_csv(list, opts = {})
    # For packing slip download link
    token = Cache.setting(Rails.configuration.domain_id, :system, 'Security Token')
    website_url = Cache.setting(Rails.configuration.domain_id, :system, 'Website URL')

    CSV.generate do |csv|
      base_cols = [
          "customer_number",
          "po_number",
          "order_date",
          "requested_ship_date",
          "item_number",
          "item_description",
          "quantity",
          "item_amount",
          "extended_value",
          "affiliate_id",
          "affiliate_order_number",
          "ship_from_name",
          "ship_from_address1",
          "ship_from_address2",
          "ship_from_city",
          "ship_from_state",
          "ship_from_zip",
          "ship_from_country",
          "ship_from_phone",
          "ship_to_name",
          "ship_to_address1",
          "ship_to_address2",
          "ship_to_city",
          "ship_to_state",
          "ship_to_zip",
          "ship_to_country",
          "ship_to_phone",
          "shipper",
          "ship_method",
          "packing_slip_url"
      ]

      csv << base_cols

      list.each do |shp|
        digest = Digest::MD5.hexdigest(shp.id.to_s + token)

        shp.items.each do |si|
          ap = AffiliateProduct.find_by(affiliate_id: shp.fulfiller.id, product_id: si.order_item.product_id)

          csv << [
              "Stock on Demand",
              shp.to_s,
              shp.order.submitted.to_date,
              shp.order.submitted.to_date,
              ap.item_number,
              ap.product.title,
              si.quantity,
              ap.price, # item_amount
              si.quantity * ap.price, # extended_value
              shp.order.affiliate.code.presence || "STOCKIFY",
              shp.order.external_order_name,
              shp.order.affiliate.name,
              shp.fulfiller.street1,
              shp.fulfiller.street2,
              shp.fulfiller.city,
              shp.fulfiller.state,
              shp.fulfiller.zip,
              shp.fulfiller.country,
              shp.fulfiller.phone,
              shp.recipient_name,
              shp.recipient_street1,
              shp.recipient_street2,
              shp.recipient_city,
              shp.recipient_state,
              shp.recipient_zip,
              shp.recipient_country,
              shp.order.contact_phone,
              "",
              "", # ship_method
              "#{website_url}/admin/store/shipments/#{shp.id}/packing_slip?digest=#{digest}"
          ]
        end
      end
    end
  end

  def set_uuid
    self.uuid = Rails.configuration.system_prefix + "_shp_" + "#{order_id}_#{sequence}" if uuid.blank?
  end

  def invoice_posted?
    Payment.exists?(payable_type: :shipment, payable_id: id)
  end

  def same_content?(shipment)
    return false if shipment.items.length != items.length

    shipment.items.each do |i|
      if !items.any? { |x| x.order_item.product_id == i.order_item.product_id && x.quantity == i.quantity }
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

    if statuses == ["shipped"] || statuses == ["cancelled"]
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

  # cost of goods
  def calculate_seller_cogs
    subtotal = 0
    items.each { |item| subtotal += item.quantity * item.order_item.unit_price }
    subtotal
  end

  # get shipment cost based on store_product_shipping_rates table
  def calculate_seller_shipping_fee
    cost = 0.00

    items.each do |i|
      sr = ProductShippingRate.find_by!(product_id: i.order_item.product_id, destination_country_code: recipient_country, ship_method: :standard)
      cost += sr.get_cost(i.quantity)
    end

    cost
  end

  def calculate_seller_transaction_fee
    ba = BillingArrangement.find_by(affiliate_id: fulfilled_by_id, seller_id: order.affiliate_id)

    if ba.nil?
      order.affiliate.transaction_fee + (calculate_seller_cogs * order.affiliate.transaction_percent / 100.0)
    else
      ba.seller_transaction_fee + (calculate_seller_cogs * ba.seller_transaction_percent / 100.0)
    end
  end

  def calculated_weight
    weight = 0.0
    items.each do |si|
      raise "Item weight not set for #{si.order_item.item_number}" if si.order_item.product.item_weight.nil?
      weight += si.order_item.product.item_weight * si.quantity
    end
    weight * 1.1 # account for packaging materials
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
