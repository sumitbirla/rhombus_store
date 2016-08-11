# == Schema Information
#
# Table name: store_inventory_transactions
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  shipment_id       :integer
#  purchase_order_id :integer
#  num_items         :integer
#  timestamp         :datetime
#  notes             :text(65535)
#  created_at        :datetime
#  updated_at        :datetime
#

class InventoryTransaction < ActiveRecord::Base
  self.table_name = "inv_transactions"
  before_save :update_total
  belongs_to :user
  has_many :items, class_name: "InventoryTransactionItem", dependent: :destroy
  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: lambda { |attrs| attrs['sku'].blank? }
  
  def update_total
    self.num_items = items.sum(:quantity)
  end
end
