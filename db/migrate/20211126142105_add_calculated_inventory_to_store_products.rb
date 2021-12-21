class AddCalculatedInventoryToStoreProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :store_products, :calculated_inventory, :integer, null: false, default: 0, after: :fulfiller_id
  end
end
