class Admin::Store::VouchersController < Admin::BaseController
  def destroy
    authorize Voucher.destroy(params[:id])
    redirect_back(fallback_location: admin_root_path)
  end

  def issue
    @voucher = authorize Voucher.find(params[:id])
    @voucher.update_attribute(:issued, true)
    redirect_back(fallback_location: admin_root_path)
  end
end
