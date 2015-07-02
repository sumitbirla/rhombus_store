require 'mail'

class SendInvoiceJob < ActiveJob::Base
  queue_as :default

  def perform(shipment_id, user_id)

    Mail.defaults do
      delivery_method :smtp, { :enable_starttls_auto => false  }
    end
    
    token = Cache.setting(Rails.configuration.domain_id, :system, 'Security Token')
    website_url = Cache.setting(Rails.configuration.domain_id, :system, 'Website URL')
    
    shipment = Shipment.find(shipment_id)
    o = shipment.order
    digest = Digest::MD5.hexdigest(shipment_id.to_s + token) 
    url = website_url + "/admin/store/shipments/#{shipment.id}/invoice?digest=#{digest}" 
      
    output_file = "/tmp/#{SecureRandom.hex(6)}.pdf"
    system "wkhtmltopdf #{url} #{output_file}"
    
    Mail.deliver do
      from      Cache.setting(Rails.configuration.domain_id, :system, 'From Email Address')
      to        shipment.order.notify_email
      subject   "Invoice for #{o.external_order_id.blank? ? "order ##{o.id}" : o.external_order_id}"
      body      "Invoice attached:\n\n"
      add_file  output_file
    end
    
    File.delete(output_file)
    
    OrderHistory.create(order_id: o.id, 
                        user_id: user_id, 
                        event_type: :invoice_send,
                        amount: shipment.invoice_amount,
                        system_name: 'Rhombus', 
                        identifier: shipment.to_s,
                        comment: o.notify_email )
  end
end
