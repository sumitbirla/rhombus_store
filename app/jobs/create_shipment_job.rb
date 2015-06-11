class CreateShipmentJob < ActiveJob::Base
  queue_as :default

  def perform(order_id)
    order = Order.find_by(order_id)
    return if order.nil?
    
    order.create_shipment(nil)
  end
end
