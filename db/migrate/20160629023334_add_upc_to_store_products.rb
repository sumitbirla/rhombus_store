class AddUpcToStoreProducts < ActiveRecord::Migration
  def change
    add_column :store_products, :upc, :string, after: :sku
  end
end
