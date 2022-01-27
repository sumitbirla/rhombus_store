class AddTracksInventoryToCoreAffiliates < ActiveRecord::Migration[6.1]
  def change
    add_column :core_affiliates, :tracks_inventory, :boolean, null: false, default: true, before: :created_at
  end
end
