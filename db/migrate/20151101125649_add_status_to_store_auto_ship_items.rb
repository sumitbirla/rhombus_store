class AddStatusToStoreAutoShipItems < ActiveRecord::Migration
  def change
    add_column :store_auto_ship_items, :status, :string, null: false
  end
end
