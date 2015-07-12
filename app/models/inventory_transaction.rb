class InventoryTransaction < ActiveRecord::Base
  self.table_name = "store_inventory_transactions"
  before_save :update_total
  belongs_to :user
  has_many :items, class_name: "InventoryTransactionItem", dependent: :destroy
  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: lambda { |attrs| attrs['sku'].blank? }
  
  def update_total
    self.num_items = items.sum(:quantity)
  end
end
