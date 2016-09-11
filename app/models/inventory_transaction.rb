# == Schema Information
#
# Table name: inv_transactions
#
#  id                    :integer          not null, primary key
#  user_id               :integer          not null
#  entity_type           :string(255)      default(""), not null
#  entity_id             :integer
#  notes                 :text(65535)
#  inventory_items_count :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class InventoryTransaction < ActiveRecord::Base
  self.table_name = "inv_transactions"
  
  belongs_to :user
  has_many :items, class_name: "InventoryItem", dependent: :destroy
  accepts_nested_attributes_for :items, reject_if: lambda { |x| x['inventoriable_id'].blank? }, allow_destroy: true
  
end
