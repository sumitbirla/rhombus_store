class AddDomainIdToStoreShippingOptions < ActiveRecord::Migration
  def change
    add_column :store_shipping_options, :domain_id, :integer, after: :id, null: false
  end
end
