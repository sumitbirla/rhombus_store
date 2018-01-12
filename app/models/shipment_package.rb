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
