class AddThirdPartyBillingToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :third_party_billing, :boolean, null: false, default: false
  end
end
