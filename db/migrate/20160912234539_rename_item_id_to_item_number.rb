class RenameItemIdToItemNumber < ActiveRecord::Migration
  def change
	rename_column :store_order_items, :item_id, :item_number
  end
end
