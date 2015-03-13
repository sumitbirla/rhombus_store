class OrderMailer < ActionMailer::Base

  default from: "#{Cache.setting(Rails.configuration.domain_id, :system, 'From Email Name')} <#{Cache.setting(Rails.configuration.domain_id, :system, 'From Email Address')}>"


  def order_submitted(order, user_id)
    @order = order
    bcc = Cache.setting(order.domain_id, 'eCommerce', 'Order Copy Recipient')

    options = {
        address: Cache.setting(order.domain_id, :system, 'SMTP Server'),
        openssl_verify_mode: 'none'
    }
    mail(to: order.notify_email,
         bcc: bcc,
         subject: "Order ##{order.id} submitted",
         delivery_method_options: options)
         
   OrderHistory.create(order_id: order.id, 
                       user_id: user_id, 
                       event_type: :confirmation_email,
                       system_name: 'Rhombus',
                       comment: order.notify_email)
  end
  
  
  def order_shipped(shipment)
    @shipment = shipment
    bcc = Cache.setting(shipment.order.domain_id, 'eCommerce', 'Order Copy Recipient')

    options = {
        address: Cache.setting(order.domain_id, :system, 'SMTP Server'),
        openssl_verify_mode: 'none'
    }
    mail(to: shipment.order.notify_email,
         bcc: bcc,
         subject: "Order ##{@shipment.order.id} has shipped",
         delivery_method_options: options)
  end

end