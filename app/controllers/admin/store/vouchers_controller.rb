class Admin::Store::VouchersController < Admin::BaseController
  def index
  end

  def new
  end

  def create
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
    Voucher.destroy(params[:id])
    redirect_to :back
  end
end
