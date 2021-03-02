# == Schema Information
#
# Table name: store_auto_ship_items
#
#  id             :integer          not null, primary key
#  days           :integer          default(30), not null
#  last_shipped   :date
#  next_ship_date :date
#  quantity       :integer          not null
#  status         :string(255)      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  product_id     :integer          not null
#  user_id        :integer          not null
#
# Indexes
#
#  index_store_auto_ship_items_on_product_id  (product_id)
#  index_store_auto_ship_items_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_auto_ship_items_product_id  (product_id => store_products.id)
#

class AutoShipItem < ActiveRecord::Base
  include Exportable

  self.table_name = "store_auto_ship_items"
  belongs_to :user
  belongs_to :product

  validates_presence_of :user_id, :product_id, :quantity, :days, :next_ship_date, :status
  validates_numericality_of :quantity, greater_than: 0

  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end
