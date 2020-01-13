class AddOptionFieldsToStoreProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :store_products, :option_name, :string, after: "group"
    add_column :store_products, :option2_name, :string, after: :option_sort
    add_column :store_products, :option2_title, :string, after: :option2_name
    add_column :store_products, :option2_sort, :integer, after: :option2_title
    add_column :store_products, :option3_name, :string, after: :option2_sort
    add_column :store_products, :option3_title, :string, after: :option3_name
    add_column :store_products, :option3_sort, :integer, after: :option3_title
  end
end
