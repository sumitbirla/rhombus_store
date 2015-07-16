# == Schema Information
#
# Table name: store_external_coupons
#
#  id            :integer          not null, primary key
#  daily_deal_id :integer          not null
#  code          :string(255)      not null
#  allocated     :boolean          not null
#  created_at    :datetime
#  updated_at    :datetime
#

class ExternalCoupon < ActiveRecord::Base
  self.table_name = "store_external_coupons"
  belongs_to :daily_deal
end
