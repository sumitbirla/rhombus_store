class OrderMailer < ActionMailer::Base

  default from: "#{Cache.setting('System', 'From Email Name ')} <#{Cache.setting('System', 'From Email Address')}>"


  def order_submitted(order)
    @order = order
    @website_url  = Cache.setting('System', 'Website URL')
    @website_name = Cache.setting('System', 'Website Name')
    bcc = Cache.setting('eCommerce', 'Order Copy Recipient')

    options = {
        address: Cache.setting('System', 'SMTP Server'),
        openssl_verify_mode: 'none'
    }
    mail(to: order.notify_email,
         bcc: bcc,
         subject: "Order ##{order.id} submitted",
         delivery_method_options: options)
  end
  
  
  def order_shipped(shipment)
    @shipment = shipment
    @website_url  = Cache.setting('System', 'Website URL')
    @website_name = Cache.setting('System', 'Website Name')
    bcc = Cache.setting('eCommerce', 'Order Copy Recipient')

    options = {
        address: Cache.setting('System', 'SMTP Server'),
        openssl_verify_mode: 'none'
    }
    mail(to: shipment.order.notify_email,
         bcc: bcc,
         subject: "Order ##{@shipment.order.id} has shipped",
         delivery_method_options: options)
  end

end