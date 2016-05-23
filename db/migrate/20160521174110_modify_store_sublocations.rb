class ModifyStoreSublocations < ActiveRecord::Migration
  def change
	add_column :store_sublocations, :row, :string, null: false
	add_column :store_sublocations, :shelf, :string, null: false
	add_column :store_sublocations, :segment, :string, null: false
	add_column :store_sublocations, :depth, :decimal, null: false, precision: 5,  scale: 2
	add_column :store_sublocations, :height, :decimal, null: false, precision: 5,  scale: 2
	add_column :store_sublocations, :width, :decimal, null: false, precision: 5,  scale: 2
	add_column :store_sublocations, :max_available_width, :decimal, null: false, precision: 5,  scale: 2
	add_column :store_sublocations, :large_box, :boolean, null: false, default: false
	add_column :store_sublocations, :heavy_box, :boolean, null: false, default: false
	add_column :store_sublocations, :holding_area, :boolean, null: false, default: false
  remove_column :store_sublocations, :zone, :string, null: false
	remove_column :store_sublocations, :aisle, :string
	remove_column :store_sublocations, :bay, :string
	remove_column :store_sublocations, :level, :string
	remove_column :store_sublocations, :section, :string
  end
end
