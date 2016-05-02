# == Schema Information
#
# Table name: store_purchase_orders
#
#  id            :integer          not null, primary key
#  affiliate_id  :integer
#  supplier_id   :integer
#  status        :string(255)
#  issue_date    :date
#  due_date      :date
#  ship_method   :string(255)
#  payment_terms :string(255)
#  ship_to       :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  notes         :text(65535)
#

class PurchaseOrder < ActiveRecord::Base
  self.table_name = "store_purchase_orders"
  
  belongs_to :affiliate
  belongs_to :supplier, class_name: 'Affiliate'
  has_many :items, class_name: 'PurchaseOrderItem', dependent: :destroy
  validates_presence_of :affiliate, :supplier, :issue_date, :status
  accepts_nested_attributes_for :items, reject_if: lambda { |x| x['sku'].blank? }, allow_destroy: true
  
  def total_amount
    amt = 0.0
    items.each { |i| amt += i.quantity * i.unit_price}
    amt
  end
  
  def amount_owed
    amt = 0.0
    items.each { |i| amt += i.quantity_received * i.unit_price}
    amt
  end
end
