class RemoveCommittedFromStoreProducts < ActiveRecord::Migration
  def change
	remove_column :store_products, :committed, :integer
	remove_column :store_products, :shipping_lead_time, :integer
  end
end
