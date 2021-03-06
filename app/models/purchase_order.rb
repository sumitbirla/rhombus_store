# == Schema Information
#
# Table name: inv_purchase_orders
#
#  id            :integer          not null, primary key
#  due_date      :date
#  issue_date    :date
#  notes         :text(65535)
#  payment_terms :string(255)
#  ship_method   :string(255)
#  ship_to       :string(255)
#  status        :string(255)
#  uuid          :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  affiliate_id  :integer
#  supplier_id   :integer
#
# Indexes
#
#  index_store_purchase_orders_on_affiliate_id  (affiliate_id)
#

class PurchaseOrder < ActiveRecord::Base
  include Exportable

  self.table_name = "inv_purchase_orders"
  after_create :set_uuid

  belongs_to :affiliate
  belongs_to :supplier, class_name: 'Affiliate'
  has_many :items, class_name: 'PurchaseOrderItem', dependent: :destroy
  has_many :inventory_transactions, foreign_key: :external_id, primary_key: :uuid, dependent: :destroy
  validates_presence_of :affiliate, :supplier, :issue_date, :status
  accepts_nested_attributes_for :items, reject_if: lambda { |x| x['sku'].blank? }, allow_destroy: true

  def set_uuid
    self.uuid = Rails.configuration.system_prefix + "_po_" + "#{id}"
    update_column(:uuid, uuid)
  end

  def total_amount
    amt = 0.0
    items.each { |i| amt += i.quantity * i.unit_price }
    amt
  end

  def amount_owed
    amt = 0.0
    items.each { |i| amt += i.quantity_received * i.unit_price }
    amt
  end

  def update_received_counts
    items.each do |i|
      i.quantity_received = 0
      inventory_transactions.each do |t|
        t.items.each { |ti| i.quantity_received += ti.quantity if ti.sku == i.sku }
      end
      i.update_status
    end

    update_status
    save
  end

  def update_status
    if items.all? { |x| x.status == 'closed' }
      self.status = 'closed'
    elsif items.any? { |x| x.status == 'received' }
      self.status = 'received'
    end
  end

  def update_affiliate_products
    items.each do |item|
      p = Product.find_by(sku: item.sku)
      next if (item.supplier_code.blank? || p.nil?)

      ap = AffiliateProduct.find_or_initialize_by(affiliate_id: supplier_id, product_id: p.id)
      ap.assign_attributes(item_number: item.supplier_code, price: item.unit_price, description: item.description)
      ap.save
    end
  end

  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end

end
