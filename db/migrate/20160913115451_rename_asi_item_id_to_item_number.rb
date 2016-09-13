class RenameAsiItemIdToItemNumber < ActiveRecord::Migration
  def change
	rename_column :store_auto_ship_items, :item_id, :item_number
  end
end
