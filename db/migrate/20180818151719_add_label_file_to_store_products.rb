class AddLabelFileToStoreProducts < ActiveRecord::Migration
  def change
    add_column :store_products, :label_file, :string
  end
end
