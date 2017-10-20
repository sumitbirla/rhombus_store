# == Schema Information
#
# Table name: store_invoice_images
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  domain_id  :integer          not null
#

class InvoiceImage < ActiveRecord::Base
  self.table_name = "store_invoice_images"
  has_many :pictures, -> { order :sort }, as: :imageable
  belongs_to :domain
  
  # PUNDIT
  def self.policy_class
    ApplicationPolicy
  end
end
