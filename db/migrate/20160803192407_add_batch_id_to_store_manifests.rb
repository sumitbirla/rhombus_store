class AddBatchIdToStoreManifests < ActiveRecord::Migration
  def change
    add_column :store_manifests, :batch_id, :string
  end
end
