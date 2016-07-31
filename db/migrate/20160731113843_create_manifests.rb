class CreateManifests < ActiveRecord::Migration
  def change
    create_table :store_manifests do |t|
      t.date :day, null: false
      t.string :carrier, null: false
      t.integer :shipment_count
      t.text :result
      t.string :status, null: false
      t.string :document_url
      t.boolean :pickup_requested, null: false, default: false

      t.timestamps null: false
    end
	add_column :store_shipments, :manifest_id, :integer
  end
end
