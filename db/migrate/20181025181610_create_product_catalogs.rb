class CreateProductCatalogs < ActiveRecord::Migration
  def change
    create_table :store_product_catalogs do |t|
      t.integer :product_id, null: false
      t.integer :catalog_id, null: false

      t.timestamps null: false
    end
  end
end
