class Admin::Store::VouchersController < Admin::BaseController
  def destroy
    Voucher.destroy(params[:id])
    redirect_to :back
  end
  
  def issue
    Voucher.find(params[:id]).update_attribute(:issued, true)
    redirect_to :back
  end
end
