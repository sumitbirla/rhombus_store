# == Schema Information
#
# Table name: order_items
#
#  id                  :integer          not null, primary key
#  order_id            :integer          not null
#  product_id          :integer          not null
#  affiliate_id        :integer
#  variation           :string(255)
#  quantity            :integer          not null
#  unit_price          :decimal(10, 2)   not null
#  uploaded_file       :string(255)
#  upload_file_preview :string(255)
#  start_x_percent     :integer
#  start_y_percent     :integer
#  width_percent       :integer
#  height_percent      :integer
#  custom_text         :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#

class OrderItem < ActiveRecord::Base
  self.table_name = "store_order_items"
  belongs_to :order
  belongs_to :product
  belongs_to :affiliate
  
  validates_presence_of :quantity, :order_id, :product_id, :unit_price
end
