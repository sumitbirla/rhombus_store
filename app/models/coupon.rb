# == Schema Information
#
# Table name: store_coupons
#
#  id               :integer          not null, primary key
#  code             :string(255)      not null
#  description      :text(65535)
#  discount_amount  :decimal(10, 2)
#  discount_percent :decimal(5, 2)
#  expire_time      :datetime         not null
#  free_shipping    :boolean
#  max_per_user     :integer
#  max_uses         :integer
#  min_order_amount :decimal(10, 2)
#  start_time       :datetime         not null
#  times_used       :integer          not null
#  created_at       :datetime
#  updated_at       :datetime
#  daily_deal_id    :integer
#  product_id       :integer
#
# Indexes
#
#  index_coupons_on_product_id  (product_id)
#

class Coupon < ActiveRecord::Base
  include Exportable

  self.table_name = "store_coupons"
  belongs_to :product
  belongs_to :daily_deal
  validates_presence_of :code, :start_time, :expire_time, :description, :max_uses, :max_per_user, :times_used
  validate :amount_xor_percent

  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end

  private

  def amount_xor_percent
    if !(discount_amount.blank? ^ discount_percent.blank?)
      errors[:base] << "Specify a discount amount or percent, not both"
    end
  end
end
