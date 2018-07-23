# == Schema Information
#
# Table name: inv_items
#
#  id                       :integer          not null, primary key
#  inventory_transaction_id :integer          not null
#  sku                      :string(255)      not null
#  inventory_location_id    :integer          not null
#  quantity                 :integer          not null
#  lot                      :string(255)
#  expiration               :integer
#  cost                     :decimal(8, 2)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class InventoryItem < ActiveRecord::Base
  establish_connection :inventorydb
	
  self.table_name = "inv_items"
  validates_presence_of :sku, :quantity, :inventory_location_id
  belongs_to :inventory_location
  belongs_to :inventory_transaction
  
  
  def self.to_csv(list, opts = {})
  
    CSV.generate do |csv|
      cols = [:sku, :lot, :expiration, :location]
      csv << cols
      list.each { |x| csv << [x.sku, x.lot, x.formatted_expiration, x.inventory_location.name] }
    end
  
  end
  
  
  # given a SKU and quantity,  this method returns locations from where product can be pulled, oldest ones first
  def self.get(sku, count)
    items = InventoryItem.where(sku: sku)
                         .group(:inventory_location_id, :lot)
                         .order("expiration, quantity")
                         .select("lot, expiration, inventory_location_id, sum(quantity) as quantity")
                         
    available = items.collect { |x| x.quantity }.sum
    raise "Insufficient inventory for SKU:#{sku}.  Requested: #{count}   available: #{available}" if available < count
    
    ret = []
    remaining = count
    
    items.each do |i|
      next if i.quantity == 0
      ret_item = InventoryItem.new(
                    sku: sku,
                    lot: i.lot,
                    expiration: i.expiration,
                    inventory_location_id: i.inventory_location_id,
                    quantity: [i.quantity, remaining].min * -1)
                    
      ret << ret_item
      remaining = count - ret.collect{ |x| x.quantity }.sum.abs
      break if remaining == 0
    end
    
    ret
  end
  
  def formatted_expiration
    return "n/a" if expiration.blank?
    s = expiration.to_s
    s[2,2] + "/" + s[0,2]
  end
end
