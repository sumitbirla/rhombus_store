# == Schema Information
#
# Table name: inv_transactions
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  shipment_id       :integer
#  purchase_order_id :integer
#  notes             :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class InventoryTransaction < ActiveRecord::Base
  self.table_name = "inv_transactions"

  belongs_to :affiliate
  has_many :items, class_name: "InventoryItem", dependent: :destroy
  accepts_nested_attributes_for :items, reject_if: lambda { |x| x['sku'].blank? }, allow_destroy: true

  # Parse a text file containing inventory and return an InventoryTransaction instance
  #
  # @params [affiliate_id] the affiliate (fulfiller) who has uploaded this file
  # @param [Array] lines an array of lines of text in the Inventory file returned by File.readlines().
  # @return [InventoryTransaction] the newly instantiated object.  Not persisted to database
  #
  def self.parse(affiliate_id, lines)
    aff = Affiliate.find(affiliate_id)
    valid_item_numbers = AffiliateProduct.where(affiliate_id: aff.id).pluck(:item_number)
    skus = Set.new(valid_item_numbers)
    tran = InventoryTransaction.new(affiliate_id: aff.id, bulk_import: true)

    # If a file has more lines than expected, i.e. more than the products in database
    # then log an error
    if lines.length > skus.length + 10000
      tran.errors.add(:base, "Too many records (#{lines.length}) in file, skipped parsing.")
      return
    end

    lines.each_with_index do |line, index|
      line.gsub!("\t\t", "\t") # delete any instances of multiple tabs
      row = line.split(/\t|,/).map(&:strip) # split by comma or tab

      if !skus.include?(row[0])
        tran.errors.add(:base, "Line #{index}: Item number '#{row[0]}' not found.") unless index == 0
        next
      end

      tran.items.build(sku: aff.code + "-" + row[0], quantity: row[1])
    end

    tran.errors.add(:base, "Inventory data has no valid items.") if tran.items.empty?
    tran
  end

  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end
