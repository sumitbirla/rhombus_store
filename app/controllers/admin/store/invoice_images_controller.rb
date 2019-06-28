class Admin::Store::InvoiceImagesController < Admin::BaseController
  def index
    authorize InvoiceImage.new
    @invoice_image = InvoiceImage.find_by(id: 1)
    @invoice_image = InvoiceImage.create(domain_id: Rails.configuration.domain_id) if @invoice_image.nil?
  end
end
