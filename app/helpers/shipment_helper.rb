module ShipmentHelper

  def shipment_status(shipment)

    css = "label-warning"

    if shipment.status == 'shipped'
      css = 'label-success'
    elsif shipment.status == 'void'
      css = 'label-danger'
    end

    "<span class='label #{css}'>#{shipment.status}</span>".html_safe
  end

  def carrier_image(carrier)
    if carrier == 'USPS'
      url = 'https://easypost-static.s3.amazonaws.com/assets/usps-logo-ca-ab840464727a0e5cb99f646e3a3d6df4.png'
    elsif carrier == 'FedEx'
      url = 'https://easypost-static.s3.amazonaws.com/assets/fedex-logo-ca-134505425edf2e97be7f5f2463307e12.png'
    elsif carrier == 'UPS'
      url = 'https://easypost-static.s3.amazonaws.com/assets/ups-logo-ca-05b6a55f022078a4a12ec7e58e897c6b.png'
    else
      return "<h4>#{carrier}</h4>".html_safe
    end

    "<img src='#{url}' alt='#{carrier}' />".html_safe
  end

  def tracking_url(shipment)
    if shipment.class.name == "String"
      carrier, tracking = shipment.split(":")
      carrier = carrier.downcase
      url = "http://www.fedex.com/Tracking?action=track&tracknumbers=#{tracking}" if carrier.include?("fedex")
      url = "http://wwwapps.ups.com/WebTracking/track?track=yes&trackNums=#{tracking}" if carrier.include?("ups")
      url = "https://tools.usps.com/go/TrackConfirmAction_input?qtc_tLabels1=#{tracking}" if carrier.include?("usps")
    else
      carrier = shipment.carrier.downcase
      url = "http://www.fedex.com/Tracking?action=track&tracknumbers=#{shipment.tracking_number}" if carrier.include?("fedex")
      url = "http://wwwapps.ups.com/WebTracking/track?track=yes&trackNums=#{shipment.tracking_number}" if carrier.include?("ups")
      url = "https://tools.usps.com/go/TrackConfirmAction_input?qtc_tLabels1=#{shipment.tracking_number}" if carrier.include?("usps")
    end

    url
  end

end