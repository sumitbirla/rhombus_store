class AddCalculatedInventoryToStoreProducts < ActiveRecord::Migration[6.1]
  def change
    add_column :store_products, :calculated_inventory, :integer, after: :fulfiller_id
  end
end
