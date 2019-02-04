class AddAffiliateShippingAccountToStoreShipments < ActiveRecord::Migration
  def change
    add_column :store_shipments, :affiliate_shipping_account, :boolean, null: false, default: false, after: :fulfilled_by_id
  end
end
