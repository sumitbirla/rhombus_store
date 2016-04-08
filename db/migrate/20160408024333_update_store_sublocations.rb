class UpdateStoreSublocations < ActiveRecord::Migration
  def change
	add_column :store_sublocations, :zone, :string, null: false
	add_column :store_sublocations, :aisle, :string
	add_column :store_sublocations, :bay, :string
	add_column :store_sublocations, :level, :string
	add_column :store_sublocations, :section, :string
	add_column :store_sublocations, :notes, :text
	remove_column :store_sublocations, :name
	remove_column :store_sublocations, :description
	add_column :store_inventory_transaction_items, :sublocation_id, :integer, null: false
  end
end
