class AddAutoshipMonthsToStoreOrderItems < ActiveRecord::Migration
  def change
    add_column :store_order_items, :autoship_months, :integer, null: false, default: 0
  end
end
