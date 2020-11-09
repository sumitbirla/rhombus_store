class StockifyFulfillmentJob < ActiveJob::Base
  queue_as :default

  # Uploads order fulfillment feed for a given shipment to Amazon. Given a shipment id, 
  # the items in the shipment as marked as shipped along with carrier and tracking code.
  #
  # @param shipment [Integer] id of the shipment that has been shipped.
  def perform(shipment_id)
    shp = Shipment.find(shipment_id)
    file_path = Setting.get(shp.order.domain_id, :ecommerce, "Edi Path")
    file_path += "/incoming/tracking/tracking_#{DateTime.now.strftime("%F_%H%M%S")}.txt"

    s = StringIO.new

    shp.items.each do |i|
      s << [shp.order.external_order_id,
            "Invoice ID",
            i.order_item.item_number,
            i.quantity,
            "SHIPPED",
            shp.recipient_name,
            shp.ship_date,
            shp.carrier.sub("FedExSmartPost", "FedEx SmartPost"),
            shp.ship_method,
            shp.tracking_number,
            "", "", "", ""
      ].join("\t")
      s << "\n"
    end

    File.write(file_path, s.string)
  end
end
