# == Schema Information
#
# Table name: store_sales_channels
#
#  id         :integer          not null, primary key
#  code       :string(255)      not null
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SalesChannel < ActiveRecord::Base
  self.table_name = "store_sales_channels"
  has_many :orders
end
