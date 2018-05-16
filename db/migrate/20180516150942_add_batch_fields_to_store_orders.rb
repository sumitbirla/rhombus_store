class AddBatchFieldsToStoreOrders < ActiveRecord::Migration
  def change
    add_column :store_orders, :batch_id, :integer
    add_column :store_orders, :financial_status, :string
    add_column :store_orders, :fulfillment_status, :string
  end
end
