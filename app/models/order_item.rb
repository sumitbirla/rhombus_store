# == Schema Information
#
# Table name: store_order_items
#
#  id                  :integer          not null, primary key
#  order_id            :integer          not null
#  product_id          :integer
#  daily_deal_id       :integer
#  affiliate_id        :integer
#  external_id         :string(255)
#  variation           :string(255)
#  quantity            :integer          not null
#  unit_price          :decimal(10, 2)   not null
#  item_id             :string(32)       not null
#  item_description    :string(255)      not null
#  autoship_months     :integer          default(0), not null
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
  belongs_to :daily_deal
  
  validates_presence_of :quantity, :order_id, :unit_price
  #validates :product_id, presence: true, if: daily_deal_id.nil?
  #validates :daily_deal_id, presence: true, if: product_id.nil?
end
