class AddResellerPriceToStoreProducts < ActiveRecord::Migration
  def change
    add_column :store_products, :reseller_price, :decimal, scale: 2, precision: 10, after: :retail_map
  end
end
