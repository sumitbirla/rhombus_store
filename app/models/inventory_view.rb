class InventoryView < ApplicationRecord
  self.table_name = "view_inventory"
  self.primary_key = :sku

  def readonly?
    true
  end
end

