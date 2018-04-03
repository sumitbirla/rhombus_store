# == Schema Information
#
# Table name: store_shipment_packages
#
#  id                    :integer          not null, primary key
#  shipment_id           :integer          not null
#  tracking_number       :string(255)
#  predefined_type       :string(255)      not null
#  length                :decimal(6, 2)
#  width                 :decimal(6, 2)
#  height                :decimal(6, 2)
#  weight                :decimal(6, 2)
#  shipping_label_format :string(255)
#  shipping_label_data   :text(65535)
#  mediumtext            :text(65535)
#  carton_label_format   :string(255)
#  carton_label_data     :text(65535)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class ShipmentPackage < ActiveRecord::Base
  self.table_name = "store_shipment_packages"
  
  belongs_to :shipment
  validate :dimensions,  :if => Proc.new { |p| p.predefined_type == 'YOUR PACKAGING' }
  validates_presence_of :shipment_id
  
  def dimensions
    if length.nil? || width.nil? || height.nil?
      errors.add(:base, "Package dimensions need to be specified")
    end
  end
end
