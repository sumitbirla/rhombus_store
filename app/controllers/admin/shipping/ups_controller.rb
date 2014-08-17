class Admin::Shipping::UpsController < Admin::BaseController

  def index
    @shipment = Shipment.find(params[:shipment_id])
  end

  private

  def shipment_params
    params.require(:shipment).permit(:ship_date, :package_weight, :package_length, :package_width, :package_height, :packaging_type)
  end

end
