# == Schema Information
#
# Table name: inv_transactions
#
#  id                :integer          not null, primary key
#  archived          :boolean          default(FALSE), not null
#  bulk_import       :boolean          default(FALSE), not null
#  notes             :text(65535)
#  responsible_party :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  affiliate_id      :integer
#  external_id       :string(255)
#
# Indexes
#
#  affiliate_id  (affiliate_id)
#  external_id   (external_id)
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
    tran = InventoryTransaction.new(affiliate_id: affiliate_id, bulk_import: true)
    items = []

    # Parse each line for SKU and quantity and build a transaction object
    lines.each_with_index do |line, index|
      line.gsub!("\t\t", "\t")                    # delete any instances of multiple tabs
      row = line.split(/\t|,/).map(&:strip)       # split by comma or tab
      next if (row.length == 0 || row[0].blank?)  # skip any empty lines

      if index < 100 && !AffiliateProduct.exists?(affiliate_id: affiliate_id, item_number: row[0])
        # tran.errors.add(:base, "Line #{index}: Item number '#{row[0]}' not found.") unless index == 0
        next
      end

      # if no valid SKU's are found in the first 10 rows,  assume file is bad and return
      if index >= 100 && items.empty?
        tran.errors.add(:base, "Inventory doesn't appear to have valid item_numbers (first #{index} rows analysed).")
        return tran
      end

      items << InventoryItem.new(sku: aff.code + "-" + row[0], quantity: row[1])
    end

    tran.items = items
    tran
  end

  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end
