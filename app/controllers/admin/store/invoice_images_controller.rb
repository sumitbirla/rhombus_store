class Admin::Store::InvoiceImagesController < Admin::BaseController
  def index
    authorize InvoiceImage
    @invoice_image = InvoiceImage.find_by(id: 1)
    @invoice_image = InvoiceImage.create if @invoice_image.nil?
  end
end
