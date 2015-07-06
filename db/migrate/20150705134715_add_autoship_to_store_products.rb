class AddAutoshipToStoreProducts < ActiveRecord::Migration
  def change
    add_column :store_products, :auto_ship, :boolean, null: false, default: false
  end
end
