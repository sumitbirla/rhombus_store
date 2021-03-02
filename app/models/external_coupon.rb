# == Schema Information
#
# Table name: store_external_coupons
#
#  id            :integer          not null, primary key
#  allocated     :boolean          not null
#  code          :string(255)      not null
#  created_at    :datetime
#  updated_at    :datetime
#  daily_deal_id :integer          not null
#
# Indexes
#
#  index_external_coupons_on_daily_deal_id  (daily_deal_id)
#

class ExternalCoupon < ActiveRecord::Base
  self.table_name = "store_external_coupons"
  belongs_to :daily_deal
end
