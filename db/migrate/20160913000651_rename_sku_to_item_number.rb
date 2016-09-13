class RenameSkuToItemNumber < ActiveRecord::Migration
  def change
	rename_column :store_products, :sku, :item_number
	rename_column :store_affiliate_products, :sku, :item_number
	rename_column :store_products, :sku2, :sku
  end
end
