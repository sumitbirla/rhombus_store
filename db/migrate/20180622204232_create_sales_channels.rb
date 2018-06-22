class CreateSalesChannels < ActiveRecord::Migration
  def change
    create_table :store_sales_channels do |t|
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps null: false
    end
  end
end
