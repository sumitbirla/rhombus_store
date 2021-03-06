class Admin::Store::CouponsController < Admin::BaseController

  def index
    authorize Coupon.new
    @coupons = Coupon.order("created_at DESC")

    respond_to do |format|
      format.html { @coupons = @coupons.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data Coupon.to_csv(@coupons) }
    end
  end

  def new
    @redirect = params[:redirect]
    @coupon = authorize Coupon.new(code: 'New Coupon', times_used: 0, max_per_user: 1, product_id: params[:product_id], daily_deal_id: params[:daily_deal_id])
    render 'edit'
  end

  def create
    @coupon = authorize Coupon.new(coupon_params)

    if @coupon.save
      unless params[:redirect].blank?
        redirect_to params[:redirect]
      else
        redirect_to action: 'index', notice: 'Coupon was successfully created.'
      end
    else
      @redirect = params[:redirect]
      render 'edit'
    end
  end

  def show
    @coupon = authorize Coupon.find(params[:id])
  end

  def edit
    @redirect = params[:redirect]
    @coupon = authorize Coupon.find(params[:id])
  end

  def update
    @coupon = authorize Coupon.find(params[:id])

    if @coupon.update(coupon_params)
      unless params[:redirect].blank?
        redirect_to params[:redirect]
      else
        redirect_to action: 'index', notice: 'Coupon was successfully updated.'
      end
    else
      @redirect = params[:redirect]
      render 'edit'
    end
  end

  def destroy
    @coupon = authorize Coupon.find(params[:id])
    @coupon.destroy
    redirect_back(fallback_location: admin_root_path)
  end


  private

  def coupon_params
    params.require(:coupon).permit(:code, :description, :product_id, :daily_deal_id, :free_shipping, :discount_amount, :discount_percent,
                                   :min_order_amount, :max_uses, :max_per_user, :start_time, :expire_time, :times_used)
  end

end
