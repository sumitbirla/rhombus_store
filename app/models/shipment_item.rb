# == Schema Information
#
# Table name: shipment_items
#
#  id            :integer          not null, primary key
#  shipment_id   :integer          not null
#  order_item_id :integer          not null
#  quantity      :integer          not null
#  created_at    :datetime
#  updated_at    :datetime
#

class ShipmentItem < ActiveRecord::Base
  self.table_name = "store_shipment_items"
  attr_accessor :previously_shipped

  belongs_to :shipment
  belongs_to :order_item
  belongs_to :product
  belongs_to :affiliate
  
  def sku
    str = product.sku
    str += "-" + affiliate.code unless affiliate.nil?
    str += "-" + variation unless variation.blank?
    str 
  end
end
