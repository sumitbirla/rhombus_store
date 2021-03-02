# == Schema Information
#
# Table name: store_order_items
#
#  id                  :integer          not null, primary key
#  autoship_months     :integer          default(0), not null
#  custom_text         :string(255)
#  height_percent      :integer
#  item_description    :string(255)      not null
#  item_number         :string(32)       not null
#  quantity            :integer          default(1), not null
#  quantity_accepted   :integer          default(0), not null
#  quantity_received   :integer          default(0), not null
#  rendered_file       :string(255)
#  start_x_percent     :integer
#  start_y_percent     :integer
#  unit_price          :decimal(12, 4)   default(0.0), not null
#  upload_file_preview :string(255)
#  uploaded_file       :string(255)
#  width_percent       :integer
#  created_at          :datetime
#  updated_at          :datetime
#  daily_deal_id       :integer
#  external_id         :string(255)
#  order_id            :integer          not null
#  product_id          :integer
#
# Indexes
#
#  index_order_items_on_order_id             (order_id)
#  index_order_items_on_product_id           (product_id)
#  index_store_order_items_on_daily_deal_id  (daily_deal_id)
#
# Foreign Keys
#
#  fk_order_items_product_id  (product_id => store_products.id)
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
    uploaded_file.present? || custom_text.present?
  end

end
