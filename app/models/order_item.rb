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
#  quantity            :integer          default(1), not null
#  unit_price          :decimal(12, 4)   default(0.0), not null
#  item_number         :string(32)       not null
#  item_description    :string(255)      not null
#  autoship_months     :integer          default(0), not null
#  uploaded_file       :string(255)
#  upload_file_preview :string(255)
#  rendered_file       :string(255)
#  start_x_percent     :integer
#  start_y_percent     :integer
#  width_percent       :integer
#  height_percent      :integer
#  custom_text         :string(255)
#  quantity_accepted   :integer          default(0), not null
#  quantity_received   :integer          default(0), not null
#  created_at          :datetime
#  updated_at          :datetime
#

class OrderItem < ActiveRecord::Base
  self.table_name = "store_order_items"
  
  belongs_to :order
  belongs_to :product
  belongs_to :daily_deal
  
  has_one :shipment_item
	has_many :extra_properties, as: :extra_property, dependent: :destroy
  
  validates_presence_of :quantity, :unit_price
  #validates :product_id, presence: true, if: daily_deal_id.nil?
  #validates :daily_deal_id, presence: true, if: product_id.nil?
  
  # check to see how much of this item has already shipped
  def quantity_shipped
    qty = ShipmentItem.joins(:shipment)
                      .where("store_shipments.status = 'shipped' AND order_item_id = ?", id)
                      .sum(:quantity)
  end
  
  def personalized?
    uploaded_file.presence? || custom_text.presence?
  end
  
end
