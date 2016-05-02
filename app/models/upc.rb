# == Schema Information
#
# Table name: store_upc
#
#  id          :integer          not null, primary key
#  code        :string(255)
#  item        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  notes       :string(255)      default(""), not null
#  flags       :string(255)
#  image_label :string(255)
#

class Upc < ActiveRecord::Base
  self.table_name = "store_upc"
  
  def self.to_csv
    CSV.generate do |csv|
      csv << column_names
      all.each do |upc|
        csv << upc.attributes.values_at(*column_names)
      end
    end
  end
  
  def to_s
    code
  end
  
end
