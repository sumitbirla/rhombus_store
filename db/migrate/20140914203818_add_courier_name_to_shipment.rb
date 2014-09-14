class AddCourierNameToShipment < ActiveRecord::Migration
  def change
	  add_column :store_shipments, :courier_name, :string, after: :label_format
    add_column :store_shipments, :ship_from_email, :string, after: :ship_from_country
    add_column :store_shipments, :ship_from_phone, :string, after: :ship_from_email
  end
end
