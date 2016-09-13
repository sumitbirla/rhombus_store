# == Schema Information
#
# Table name: inv_items
#
#  id                       :integer          not null, primary key
#  inventory_transaction_id :integer          not null
#  inventoriable_type       :string(255)      default(""), not null
#  inventoriable_id         :integer          not null
#  inventory_location_id    :integer          not null
#  quantity                 :integer          not null
#  lot                      :string(255)
#  expiration               :integer
#  cost                     :decimal(8, 2)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class InventoryItem < ActiveRecord::Base
  self.table_name = "inv_items"
  belongs_to :inventoriable, polymorphic: true
  belongs_to :inventory_location
  belongs_to :inventory_transaction
end
