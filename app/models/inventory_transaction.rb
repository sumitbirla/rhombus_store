# == Schema Information
#
# Table name: inv_transactions
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  shipment_id       :integer
#  purchase_order_id :integer
#  notes             :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class InventoryTransaction < ActiveRecord::Base
  self.table_name = "inv_transactions"
  
  belongs_to :affiliate
  has_many :items, class_name: "InventoryItem", dependent: :destroy
  accepts_nested_attributes_for :items, reject_if: lambda { |x| x['sku'].blank? }, allow_destroy: true
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end
