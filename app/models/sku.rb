# == Schema Information
#
# Table name: skus
#
#  id              :integer          not null, primary key
#  code            :string(255)      default(""), not null
#  description     :string(255)      default(""), not null
#  committed       :integer          default(0), not null
#  low_threshold   :integer          default(0), not null
#  fulfilled_by_id :integer
#  supplier_id     :integer
#  created_at      :datetime
#  updated_at      :datetime
#

class Sku < ActiveRecord::Base
  self.table_name = "store_skus"
  has_many :products
  has_many :inventory
  belongs_to :fulfiller, class_name: 'Affiliate', foreign_key: 'fulfilled_by_id'
  belongs_to :supplier, class_name: 'Affiliate', foreign_key: 'supplier_id'

  def to_s
    code
  end

end
