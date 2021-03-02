# == Schema Information
#
# Table name: store_shipment_items
#
#  id             :integer          not null, primary key
#  quantity       :integer          not null
#  special_status :string(64)       default("")
#  created_at     :datetime
#  updated_at     :datetime
#  order_item_id  :integer          not null
#  shipment_id    :integer          not null
#
# Indexes
#
#  index_shipment_items_on_product_id   (order_item_id)
#  index_shipment_items_on_shipment_id  (shipment_id)
#
# Foreign Keys
#
#  store_shipment_items_ibfk_1  (order_item_id => store_order_items.id)
#

class ShipmentItem < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  self.table_name = "store_shipment_items"
  attr_accessor :previously_shipped

  belongs_to :shipment
  belongs_to :order_item
  belongs_to :inventory_location

  def to_s
    "#{order_item.item_number} (#{number_with_delimiter(quantity)})"
  end
end
