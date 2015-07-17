class AddFieldsToStoreUpc < ActiveRecord::Migration
  def change
    add_column :store_upc, :flags, :string
    add_column :store_upc, :image_label, :string
  end
end
