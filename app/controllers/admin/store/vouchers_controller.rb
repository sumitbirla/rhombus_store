class Admin::Store::VouchersController < Admin::BaseController
  def destroy
    authorize Voucher.destroy(params[:id])
    redirect_to :back
  end
  
  def issue
    @voucher = authorize Voucher.find(params[:id])
    @voucher.update_attribute(:issued, true)
    redirect_to :back
  end
end
