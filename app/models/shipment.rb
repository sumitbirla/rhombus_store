# == Schema Information
#
# Table name: shipments
#
#  id                :integer          not null, primary key
#  order_id          :integer          not null
#  sequence          :integer          not null
#  fulfilled_by_id   :integer
#  status            :string(255)      not null
#  ship_from_id      :integer          not null
#  recipient_name    :string(255)      not null
#  recipient_company :string(255)
#  recipient_street1 :string(255)      not null
#  recipient_street2 :string(255)
#  recipient_city    :string(255)      not null
#  recipient_state   :string(255)      not null
#  recipient_zip     :string(255)      not null
#  recipient_country :string(255)      not null
#  ship_method       :string(255)
#  tracking_number   :string(255)
#  ship_date         :datetime
#  ship_cost         :decimal(6, 2)
#  package_length    :integer
#  package_width     :integer
#  package_height    :integer
#  package_weight    :decimal(6, 2)
#  notes             :text
#  packaging_type    :string(255)
#  drop_off_type     :string(255)
#  courier_data      :text
#  created_at        :datetime
#  updated_at        :datetime
#  label_data        :binary(16777215)
#  label_format      :string(255)
#

class Shipment < ActiveRecord::Base
  self.table_name = "store_shipments"
  belongs_to :order
  belongs_to :fulfiller, class_name: 'User', foreign_key: 'fulfilled_by_id'
  has_many :items, class_name: 'ShipmentItem'

  validates_presence_of :ship_from_company, :ship_from_street1, :ship_from_city, :ship_from_state, :ship_from_zip, :ship_from_country
  validates_presence_of :recipient_name, :recipient_street1, :recipient_city, :recipient_state, :recipient_zip, :recipient_country

  def dimensions_available?
    !(package_length.nil? || package_width.nil? || package_height.nil?)
  end

  def to_s
    "#{order_id}-#{sequence}"
  end
end
