# == Schema Information
#
# Table name: store_inventory_transaction_items
#
#  id                       :integer          not null, primary key
#  inventory_transaction_id :integer
#  sku                      :string(255)
#  units_per_case           :integer          default(0), not null
#  cases                    :integer          default(0), not null
#  loose_items              :integer          default(0), not null
#  quantity                 :integer
#

class InventoryTransactionItem < ActiveRecord::Base
  self.table_name = "store_inventory_transaction_items"
  belongs_to :inventory_transaction
  validates_presence_of :sku, :quantity
end
