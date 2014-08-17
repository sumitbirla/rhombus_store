# == Schema Information
#
# Table name: invoice_images
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#

class InvoiceImage < ActiveRecord::Base
  self.table_name = "store_invoice_images"
  has_many :pictures, -> { order :sort }, as: :imageable
end
