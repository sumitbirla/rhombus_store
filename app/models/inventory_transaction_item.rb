class InventoryTransactionItem < ActiveRecord::Base
  self.table_name = "store_inventory_transaction_items"
  belongs_to :inventory_transaction
  validates_presence_of :sku, :quantity
end
