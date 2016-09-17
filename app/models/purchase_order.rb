# == Schema Information
#
# Table name: inv_purchase_orders
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
  include Exportable
  
  self.table_name = "inv_purchase_orders"
  
  belongs_to :affiliate
  belongs_to :supplier, class_name: 'Affiliate'
  has_many :items, class_name: 'PurchaseOrderItem', dependent: :destroy
  has_many :inventory_transactions
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
  
end
