# == Schema Information
#
# Table name: store_inventory_transaction_items
#
#  id                       :integer          not null, primary key
#  inventory_transaction_id :integer
#  sku                      :string(255)
#  quantity                 :integer
#  lot                      :string(255)      not null
#  expiration               :integer
#  sublocation_id           :integer          not null
#

class InventoryTransactionItem < ActiveRecord::Base
  self.table_name = "store_inventory_transaction_items"
  belongs_to :inventory_transaction
  belongs_to :sublocation
  validates_presence_of :sku, :quantity
end
