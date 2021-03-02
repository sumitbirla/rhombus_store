# == Schema Information
#
# Table name: store_product_sales_channels
#
#  id               :integer          not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  product_id       :integer
#  sales_channel_id :integer
#
class ProductSalesChannel < ActiveRecord::Base
  self.table_name = "store_product_sales_channels"
end
