class AddProductToStoreProductCatalogs < ActiveRecord::Migration
  def change
    add_column :store_product_catalogs, :standard_price, :decimal, null: false, precision: 10, scale: 4
    add_column :store_product_catalogs, :promotional_price, :decimal, precision: 10, scale: 4
  end
end
