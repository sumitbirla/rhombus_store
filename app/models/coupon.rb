# == Schema Information
#
# Table name: coupons
#
#  id               :integer          not null, primary key
#  code             :string(255)      not null
#  description      :text
#  product_id       :integer
#  daily_deal_id    :integer
#  free_shipping    :boolean
#  discount_amount  :decimal(10, 2)
#  discount_percent :decimal(5, 2)
#  min_order_amount :decimal(10, 2)
#  max_uses         :integer
#  max_per_user     :integer
#  times_used       :integer          not null
#  start_time       :datetime         not null
#  expire_time      :datetime         not null
#  created_at       :datetime
#  updated_at       :datetime
#

class Coupon < ActiveRecord::Base
  self.table_name = "store_coupons"
  
  belongs_to :product
  belongs_to :daily_deal
  validates_presence_of :code, :start_time, :expire_time, :description, :max_uses, :max_per_user, :times_used
  validate :amount_xor_percent
  
  private

      def amount_xor_percent
        if !(discount_amount.blank? ^ discount_percent.blank?)
          errors[:base] << "Specify a discount amount or percent, not both"
        end
      end
end
