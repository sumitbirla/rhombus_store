class AddNotesToStoreUpcs < ActiveRecord::Migration
  def change
    add_column :store_upc, :notes, :string, before: :created_at
  end
end
