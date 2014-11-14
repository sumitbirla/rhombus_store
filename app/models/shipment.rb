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
require 'net/http'
require 'uri'

class Shipment < ActiveRecord::Base
  self.table_name = "store_shipments"
  belongs_to :order
  belongs_to :fulfiller, class_name: 'User', foreign_key: 'fulfilled_by_id'
  has_many :items, class_name: 'ShipmentItem', dependent: :destroy
  
  accepts_nested_attributes_for :items, allow_destroy: true

  validates_presence_of :ship_from_company, :ship_from_street1, :ship_from_city, :ship_from_state, :ship_from_zip, :ship_from_country
  validates_presence_of :recipient_name, :recipient_street1, :recipient_city, :recipient_state, :recipient_zip, :recipient_country
  #validates_presence_of :package_weight
  
  def self.to_csv
    CSV.generate do |csv|
      cols = column_names - ['label_data']
      csv << cols
      all.each do |shipment|
        csv << shipment.attributes.values_at(*cols)
      end
    end
  end

  def dimensions_available?
    !(package_length.nil? || package_width.nil? || package_height.nil?)
  end

  def to_s
    "#{order_id}-#{sequence}"
  end
  
  def copy_easy_post(response)
    # save shipment object
    parcel = response[:parcel]
		from = response[:from_address]
		to = response[:to_address]
    plabel = response[:postage_label]
    rate = response[:selected_rate]
    
    self.assign_attributes(
      courier_name: 'EasyPost',

			ship_from_company: from[:company],
    	ship_from_street1: from[:street1],
    	ship_from_street2: from[:street2],
    	ship_from_city: from[:city],
    	ship_from_state: from[:state],
    	ship_from_zip: from[:zip],
    	ship_from_country: from[:country],

    	recipient_name: to[:name],
    	recipient_company: to[:company],
    	recipient_street1: to[:street1],
    	recipient_street2: to[:street2],
    	recipient_city: to[:city],
    	recipient_state: to[:state],
    	recipient_zip: to[:zip],
    	recipient_country: to[:country],
      
			packaging_type: parcel[:predefined_package] || 'YOUR PACKAGING',
    	package_width: parcel[:width],
    	package_length: parcel[:length],
    	package_height: parcel[:height],
    	package_weight: parcel[:weight] / 16.0
    )
    
    unless plabel.nil?
      # try to download label PNG
      label_url = plabel[:label_url]
      label_data = label_url
      begin
        label_data = Net::HTTP.get(URI.parse(label_url))
      rescue => e
      end
      
      self.assign_attributes(
        ship_date: DateTime.iso8601(plabel[:label_date]).to_date,
      	ship_method: rate[:carrier] + ' ' + rate[:service],
        ship_cost: rate[:rate],
        require_signature: response[:options][:delivery_confirmation] == 'SIGNATURE',
      	tracking_number: response[:tracking_code],
      	label_format: plabel[:label_file_type],
      	label_data: label_data,
      	courier_data: response.to_json    	
      )
    end
    
  end
end
