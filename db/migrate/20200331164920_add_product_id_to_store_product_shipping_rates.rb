class AddProductIdToStoreProductShippingRates < ActiveRecord::Migration[5.2]
  def change
    add_column :store_product_shipping_rates, :product_id, :integer, null: false, before: :code
  end
end
