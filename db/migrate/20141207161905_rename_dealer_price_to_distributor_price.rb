class RenameDealerPriceToDistributorPrice < ActiveRecord::Migration
  def change
	rename_column :store_products, :dealer_price, :distributor_price
	add_column :store_products, :retailer_price, :decimal, precision: 8, scale: 2
	add_column :store_products, :active, :boolean, null: false, default: true, after: :sku
  end
end
