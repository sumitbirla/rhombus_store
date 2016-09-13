class RemoveFieldsFromProduct < ActiveRecord::Migration
  def change
	remove_column :store_products, :distributor_price
	remove_column :store_products, :retailer_price
  end
end
