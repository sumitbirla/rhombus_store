class AddErrorsToStoreOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :store_orders, :error_messages, :text, before: :created_at
  end
end
