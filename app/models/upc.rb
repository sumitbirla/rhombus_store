# == Schema Information
#
# Table name: upcs
#
#  id         :integer          not null, primary key
#  code       :string(255)
#  item       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Upc < ActiveRecord::Base
  self.table_name = "store_upc"
end
