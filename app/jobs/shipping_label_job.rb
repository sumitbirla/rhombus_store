require 'socket'
require 'easypost'
require 'net/http'
require 'uri'

class ShippingLabelJob < ActiveJob::Base
  queue_as :default

  def perform(user_id, shipment_id, format)
    begin
      shipment = Shipment.find(shipment_id)
      courier_data = JSON.parse(shipment.courier_data)
    
      EasyPost.api_key = Cache.setting(shipment.order.domain_id, 'Shipping', 'EasyPost API Key')
      ep_shipment = EasyPost::Shipment.retrieve(courier_data['id'])
      response = ep_shipment.label({'file_format' => format})
      
      # download label
      label_url = response[:postage_label]["label_#{format}_url"]
      label_data = Net::HTTP.get(URI.parse(label_url))
      
      uri = URI(Cache.setting(shipment.order.domain_id, :shipping, 'Thermal Printer URI'))
      s = TCPSocket.new(uri.host, uri.port)
      s.send label_data, 0
      s.close
      
      memo = "Shipping label printed to #{ip_addr}"
    rescue => e
      memo = e.message
    end
    
    OrderHistory.create(order_id: shipment.order_id, user_id: user_id, event_type: :shipping_label_print, system_name: 'Rhombus', comment: memo)
  end
end
