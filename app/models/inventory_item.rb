# == Schema Information
#
# Table name: inv_items
#
#  id                       :integer          not null, primary key
#  cost                     :decimal(8, 2)
#  expiration               :integer
#  lot                      :string(255)
#  quantity                 :integer          not null
#  sku                      :string(255)      not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  inventory_location_id    :integer
#  inventory_transaction_id :integer          not null
#
# Indexes
#
#  inventory_transaction_id  (inventory_transaction_id)
#  sku                       (sku)
#

class InventoryItem < ActiveRecord::Base
  self.table_name = "inv_items"
  validates_presence_of :sku, :quantity
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
    items = InventoryItem.joins(:inventory_transaction)
                .where("inv_transactions.archived" => false)
                .where(sku: sku)
                .group(:inventory_location_id, :lot)
                .order("expiration, quantity")
                .select("lot, expiration, inventory_location_id, sum(quantity) as quantity")

    available = items.collect { |x| x.quantity }.sum

    if available < count
      raise InventoryException.new "Insufficient inventory for SKU:#{sku}.  Requested: #{count}   available: #{available}"
    end

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
      remaining = count - ret.collect { |x| x.quantity }.sum.abs
      break if remaining == 0
    end

    ret
  end

  def formatted_expiration
    return "n/a" if expiration.blank?
    s = expiration.to_s
    s[2, 2] + "/" + s[0, 2]
  end
end
