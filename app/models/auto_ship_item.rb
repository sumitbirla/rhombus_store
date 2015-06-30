class AutoShipItem < ActiveRecord::Base
  self.table_name = "store_auto_ship_items"
  belongs_to :user
  belongs_to :product
  belongs_to :affiliate
end
