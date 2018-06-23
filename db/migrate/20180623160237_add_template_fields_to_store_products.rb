class AddTemplateFieldsToStoreProducts < ActiveRecord::Migration
  def change
    add_column :store_products, :template, :boolean, null: false, default: false
    add_column :store_products, :template_product_id, :integer
  end
end
