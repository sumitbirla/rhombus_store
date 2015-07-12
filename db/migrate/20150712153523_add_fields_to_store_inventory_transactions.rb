class AddFieldsToStoreInventoryTransactions < ActiveRecord::Migration
  def change
    add_column :store_inventory_transaction_items, :units_per_case, :integer, null: false, default: 0
    add_column :store_inventory_transaction_items, :cases, :integer, null: false, default: 0
    add_column :store_inventory_transaction_items, :loose_items, :integer, null: false, default: 0
  end
end
