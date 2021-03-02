# == Schema Information
#
# Table name: store_catalogs
#
#  id         :integer          not null, primary key
#  code       :string(255)      not null
#  name       :string(255)      not null
#  url        :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Catalog < ActiveRecord::Base
  include Exportable

  self.table_name = "store_catalogs"

  validates_presence_of :name, :code
  validates_uniqueness_of :name, :code

  has_many :product_catalogs, dependent: :destroy
  has_many :products, through: :product_catalogs

  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end
