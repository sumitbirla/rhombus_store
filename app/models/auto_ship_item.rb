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
  
  before_validation :set_product_id
  
  validates_presence_of :user_id, :item_number, :product_id, :quantity, :days, :next_ship_date, :status
  validates_numericality_of :quantity, greater_than: 0
  
  def set_product_id
    sku, affiliate, self.variation = item_number.split("-")
    
    p = Product.find_by(item_number: sku)
    self.product_id = p.id unless p.nil?
 
    unless affiliate.nil?
      a = Affiliate.find_by(code: affiliate)
      self.affiliate_id = a.id unless a.nil?
    end
  end
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end
