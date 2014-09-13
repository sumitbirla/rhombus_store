module ShipmentHelper
    
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
  
end