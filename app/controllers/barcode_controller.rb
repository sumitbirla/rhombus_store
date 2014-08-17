require 'barby'
require 'barby/barcode/code_39'
require 'barby/outputter/png_outputter'

class BarcodeController < ActionController::Base

  def generate

    barcode = Barby::Code39.new(params[:code])
    blob = Barby::PngOutputter.new(barcode).to_png(height: 40, xdim: 2)

    send_data blob,  filename: "#{params[:code]}.png", type: 'image/png', disposition: 'inline'

  end

end