# == Schema Information
#
# Table name: store_auto_ship_items
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  item_number    :string(255)      not null
#  product_id     :integer          not null
#  affiliate_id   :integer
#  variation      :string(255)
#  description    :string(255)      not null
#  quantity       :integer          not null
#  days           :integer          default(30), not null
#  last_shipped   :date
#  next_ship_date :date
#  status         :string(255)      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class AutoShipItem < ActiveRecord::Base
  include Exportable
  
  self.table_name = "store_auto_ship_items"
  belongs_to :user
  belongs_to :product
  belongs_to :affiliate
end
