class AddDomainIdToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :domain_id, :integer, after: :id, null: false
  end
end
