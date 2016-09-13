# == Schema Information
#
# Table name: store_shipment_items
#
#  id             :integer          not null, primary key
#  shipment_id    :integer          not null
#  order_item_id  :integer          not null
#  product_id     :integer          not null
#  affiliate_id   :integer
#  variation      :string(255)
#  quantity       :integer          not null
#  lot            :string(255)
#  expiration     :integer
#  special_status :string(64)       default("")
#  created_at     :datetime
#  updated_at     :datetime
#

class ShipmentItem < ActiveRecord::Base
  self.table_name = "store_shipment_items"
  attr_accessor :previously_shipped

  belongs_to :shipment
  belongs_to :order_item
  belongs_to :product
  belongs_to :affiliate
  belongs_to :inventory_location
  
  def sku
    str = product.sku
    str += "-" + affiliate.code unless affiliate.nil?
    str += "-" + variation unless variation.blank?
    str 
  end
  
end
