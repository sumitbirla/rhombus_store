class AddAffiliateIdToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :affiliate_id, :integer
  end
end
