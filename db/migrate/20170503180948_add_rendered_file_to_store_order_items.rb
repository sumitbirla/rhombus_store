class AddRenderedFileToStoreOrderItems < ActiveRecord::Migration
  def change
    add_column :store_order_items, :rendered_file, :string
  end
end
