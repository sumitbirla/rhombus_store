# == Schema Information
#
# Table name: store_purchase_order_items
#
#  id                :integer          not null, primary key
#  purchase_order_id :integer          not null
#  sku               :string(32)       default(""), not null
#  quantity          :integer          default(1), not null
#  description       :string(255)
#  supplier_code     :string(255)
#  upc               :string(255)
#  unit_price        :decimal(10, 2)
#  discount          :decimal(10, 2)
#  quantity_received :integer          default(0), not null
#  status            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

class PurchaseOrderItem < ActiveRecord::Base
  self.table_name = "store_purchase_order_items"
  belongs_to :purchase_order
  validates_presence_of :sku, :quantity
  
  def status
    if quantity_received == 0
      "open"
    elsif quantity_received >= quantity
      "received"
    else
      "partial"
    end
  end
  
end
