class CreateProductShippingRates < ActiveRecord::Migration
  def change
    create_table :store_product_shipping_rates do |t|
      t.integer :product_id, null: false
      t.string :destination_country_code, limit: 2, null: false
      t.string :ship_method, null: false
      t.decimal :first_item, null: false, precision: 6, scale: 2
      t.decimal :second_item, null: false, precision: 6, scale: 2
      t.decimal :additional_items, null: false, precision: 6, scale: 2

      t.timestamps null: false
    end
  end
end
