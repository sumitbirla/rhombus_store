class MakeColumnsNullable < ActiveRecord::Migration
  def change
    change_column_null :store_products, :slug, true
    change_column_null :store_products, :brand_id, true
    change_column_null :store_products, :title, true
    change_column_null :store_products, :price, true
  end
end
