# == Schema Information
#
# Table name: store_inventory_transaction_items
#
#  id                       :integer          not null, primary key
#  inventory_transaction_id :integer
#  sku                      :string(255)
#  quantity                 :integer
#  lot                      :string(255)      not null
#  expiration               :integer
#  sublocation_id           :integer          not null
#

class InventoryItem < ActiveRecord::Base
  self.table_name = "inv_items"
  belongs_to :inventoriable, polymorphic: true
  belongs_to :inventory_location
  belongs_to :user
end
