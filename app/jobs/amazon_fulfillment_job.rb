require 'peddler'

class AmazonFulfillmentJob < ActiveJob::Base
  queue_as :default

  # Uploads order fulfillment feed for a given shipment to Amazon. Given a shipment id, 
  # the items in the shipment as marked as shipped along with carrier and tracking code.
  #
  # @param shipment [Integer] id of the shipment that has been shipped.
  def perform(shipment_id)
    shp = Shipment.find(shipment_id)

    s = StringIO.new
    s << ["order-id", "order-item-id", "quantity", "ship-date", "carrier-code", "tracking-number", "ship-method"].join("\t")

    shp.items.each do |i|
      s << "\n"
      s << [shp.order.external_order_id,
            i.order_item.external_id,
            i.quantity,
            shp.ship_date.strftime("%Y-%m-%d"),
            shp.carrier.sub("FedExSmartPost", "FedEx SmartPost"),
            shp.tracking_number,
            shp.ship_method
      ].join("\t")
    end

    d = shp.order.domain_id
    client = MWS.feeds(
        marketplace: Setting.get(d, :ecommerce, "Amazon Marketplace ID"),
        merchant_id: Setting.get(d, :ecommerce, "Amazon Merchant ID"),
        aws_access_key_id: Setting.get(d, :ecommerce, "AWS Access Key ID"),
        aws_secret_access_key: Setting.get(d, :ecommerce, "AWS Secret Access Key")
    )

    client.submit_feed(s.string, "_POST_FLAT_FILE_FULFILLMENT_DATA_")
    #File.write("./amazon.txt", s.string)
  end
end
