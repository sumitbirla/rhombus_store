class SalesChannel < ActiveRecord::Base
  self.table_name = "store_sales_channels"
  has_many :orders
end
