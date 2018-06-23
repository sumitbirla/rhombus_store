class AddSalesChannelIdToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :sales_channel_id, :integer
  end
end
