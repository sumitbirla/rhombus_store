# == Schema Information
#
# Table name: inv_purchase_order_items
#
#  id                :integer          not null, primary key
#  description       :string(255)
#  discount          :decimal(10, 2)
#  quantity          :integer          default(1), not null
#  quantity_received :integer          default(0), not null
#  sku               :string(32)       default(""), not null
#  status            :string(255)
#  supplier_code     :string(255)
#  unit_price        :decimal(12, 4)   default(0.0), not null
#  upc               :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  purchase_order_id :integer          not null
#
# Indexes
#
#  index_purchase_order_items_on_sku_id  (sku)
#

class PurchaseOrderItem < ActiveRecord::Base
  self.table_name = "inv_purchase_order_items"
  belongs_to :purchase_order
  validates_presence_of :sku, :quantity, :unit_price

  def update_status
    if quantity_received >= quantity
      self.status = 'closed'
    elsif quantity_received == 0
      self.status = 'open'
    else
      self.status = 'received'
    end
  end

end
