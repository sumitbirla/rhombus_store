class AddFieldsToStoreVouchers < ActiveRecord::Migration
  def change
    add_column :store_vouchers, :issued, :boolean
    add_column :store_vouchers, :amount_used, :decimal, null: false, default: 0.0
	remove_column :store_vouchers, :claimed_by
	remove_column :store_vouchers, :claim_time
  end
end
