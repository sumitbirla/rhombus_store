class AddReceivedToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :received, :datetime
  end
end
