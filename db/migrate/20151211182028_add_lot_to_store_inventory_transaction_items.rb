class AddLotToStoreInventoryTransactionItems < ActiveRecord::Migration
  def change
    add_column :store_inventory_transaction_items, :lot, :string, null: false
    add_column :store_inventory_transaction_items, :expiration, :integer
    remove_column :store_inventory_transaction_items, :units_per_case
    remove_column :store_inventory_transaction_items, :cases
    remove_column :store_inventory_transaction_items, :loose_items
  end
end
