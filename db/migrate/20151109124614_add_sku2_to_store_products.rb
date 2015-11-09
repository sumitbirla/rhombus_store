class AddSku2ToStoreProducts < ActiveRecord::Migration
  def change
    add_column :store_products, :sku2, :string
  end
end
