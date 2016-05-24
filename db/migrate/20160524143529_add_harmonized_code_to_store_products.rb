class AddHarmonizedCodeToStoreProducts < ActiveRecord::Migration
  def change
    add_column :store_products, :harmonized_code, :string
    remove_column :store_products, :primary_supplier_id
  end
end
