class AlterProductShippingRates < ActiveRecord::Migration
  def change
    add_column :store_product_shipping_rates, :code, :string, null: false, after: :id
    remove_column :store_product_shipping_rates, :product_id, :integer
    add_column :store_products, :shipping_code, :string, after: :special_price 
  end
end
