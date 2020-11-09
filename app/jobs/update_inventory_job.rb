class UpdateInventoryJob < ActiveJob::Base
  queue_as :default

  def perform(h = {})

    trans = InventoryTransaction.new(h)
    trans.timestamp = DateTime.now

    # this is a shipment being sent
    unless h[:shipment_id].nil?
      s = Shipment.includes(:items, [items: :product]).find(h[:shipment_id])

      s.items.each do |i|
        trans.items.build(sku: i.product.sku2,
                          quantity: -1 * i.quantity)
      end
    end

    # this is a PO being received
    unless h[:purchase_order_id].nil?
      po = PurchaseOrder.find(h[:purchase_order_id])

      po.items.each do |i|
        trans.items.build(sku: i.sku,
                          quantity: i.quantity_received)
      end
    end

    trans.save

  end

end
