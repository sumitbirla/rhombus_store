require 'socket'
require 'easypost'
require 'net/http'
require 'uri'

class ShippingLabelJob < ActiveJob::Base
  queue_as :default

  def perform(user_id, shipment_id, printer_id)
    begin
      shipment = Shipment.find(shipment_id)
      courier_data = JSON.parse(shipment.courier_data)
      printer = Printer.find(printer_id)
      mime_type = (printer.preferred_format == 'pdf' ? 'application/pdf' : 'text/plain')
    
      if shipment.affiliate_shipping_account
        EasyPost.api_key = shipment.order.affiliate.get_property("EasyPost API Key")
      else
        EasyPost.api_key = Cache.setting(shipment.order.domain_id, :shipping, 'EasyPost API Key')
      end
      
      ep_shipment = EasyPost::Shipment.retrieve(courier_data['id'])
      response = ep_shipment.label({'file_format' => printer.preferred_format})
      
      # download label
      label_url = response[:postage_label]["label_#{printer.preferred_format}_url"]
      label_data = Net::HTTP.get(URI.parse(label_url))
  
      # send to cups printer server
      job = printer.print_data(label_data, mime_type)
      
      memo = "Shipping label sent to printer '#{printer.name}, Job ID: #{job}"
    end
    
    OrderHistory.create(order_id: shipment.order_id, user_id: user_id, event_type: :shipping_label_print, system_name: 'Rhombus', comment: memo)
  end
end
