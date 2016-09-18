class RemoveMinimumOrderQuantityFromStoreProducts < ActiveRecord::Migration
  def change
	remove_column :store_products, :minimum_order_quantity, :integer
  end
end
