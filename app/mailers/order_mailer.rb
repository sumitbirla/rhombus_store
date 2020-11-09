class OrderMailer < ActionMailer::Base
  helper :image

  def order_submitted(order_id, user_id)
    @order = Order.find(order_id)
    bcc = Cache.setting(@order.domain_id, 'eCommerce', 'Order Copy Recipient')
    from_name = Cache.setting(@order.domain_id, :system, 'From Email Name')
    from_email = Cache.setting(@order.domain_id, :system, 'From Email Address')

    mail(from: "#{from_name} <#{from_email}>",
         to: @order.notify_email,
         bcc: bcc,
         subject: "Order ##{@order.id} submitted")

    OrderHistory.create(order_id: @order.id,
                        user_id: user_id,
                        event_type: :confirmation_email,
                        system_name: 'Rhombus',
                        comment: @order.notify_email)
  end


  def order_shipped(shipment_id, user_id)
    @shipment = Shipment.find(shipment_id)
    bcc = Cache.setting(@shipment.order.domain_id, 'eCommerce', 'Order Copy Recipient')
    from_name = Cache.setting(@shipment.order.domain_id, :system, 'From Email Name')
    from_email = Cache.setting(@shipment.order.domain_id, :system, 'From Email Address')

    if @shipment.order.auto_ship
      subject = "Autoship ##{@shipment.order.id} is on its way"
    else
      subject = "Order ##{@shipment.order.id} has shipped"
    end

    mail(from: "#{from_name} <#{from_email}>",
         to: @shipment.order.notify_email,
         bcc: bcc,
         subject: subject)

    OrderHistory.create(order_id: @shipment.order.id,
                        user_id: user_id,
                        event_type: :email_shipping_confirmation,
                        system_name: 'Rhombus',
                        identifier: @shipment.id,
                        comment: @shipment.order.notify_email)
  end

end