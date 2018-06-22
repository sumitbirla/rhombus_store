class CreateProductSalesChannels < ActiveRecord::Migration
  def change
    create_table :store_product_sales_channels do |t|
      t.references :product
      t.references :sales_channel

      t.timestamps null: false
    end
  end
end
