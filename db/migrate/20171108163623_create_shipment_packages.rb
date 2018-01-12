class CreateShipmentPackages < ActiveRecord::Migration
  def change
    create_table :store_shipment_packages do |t|
      t.integer :shipment_id, null: false
      t.string :tracking_number
      t.string :predefined_type, null: false
      t.decimal :length, precision: 6, scale: 2
      t.decimal :width, precision: 6, scale: 2
      t.decimal :height, precision: 6, scale: 2
      t.decimal :weight, precision: 6, scale: 2
      t.string :shipping_label_format
      t.text :shipping_label_data, "mediumtext"
      t.string :carton_label_format
      t.text :carton_label_data, "mediumtext"

      t.timestamps null: false
    end
  end
end
