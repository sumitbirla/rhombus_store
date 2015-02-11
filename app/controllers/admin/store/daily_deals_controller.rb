class Admin::Store::DailyDealsController < Admin::BaseController
  
  def index
    @daily_deals = DailyDeal.page(params[:page]).order('start_time DESC')
  end

  def new
    @daily_deal = DailyDeal.new short_tag_line: 'New daily deal', theme: 'default', facebook_posts: 0, facebook_clicks: 0, number_sold: 0
    render 'edit'
  end

  def create
    @daily_deal = DailyDeal.new(daily_deal_params)
    @daily_deal.uuid = SecureRandom.uuid
    
    if @daily_deal.save
      redirect_to action: 'show', id: @daily_deal.id, notice: 'Daily Deal was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @daily_deal = DailyDeal.find(params[:id])
  end

  def edit
    @daily_deal = DailyDeal.find(params[:id])
  end

  def update
    @daily_deal = DailyDeal.find(params[:id])
    
    if @daily_deal.update(daily_deal_params)
      redirect_to admin_store_daily_deal_path(@daily_deal), notice: 'Daily Deal was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @daily_deal = DailyDeal.find(params[:id])
    @daily_deal.destroy
    redirect_to action: 'index', notice: 'Daily Deal has been deleted.'
  end
  
  def pictures
    @daily_deal = DailyDeal.find(params[:id])
  end
  
  def coupons
    @daily_deal = DailyDeal.find(params[:id])
  end
  
  def items
    @daily_deal = DailyDeal.find(params[:id])
  end
  
  def locations
    @daily_deal = DailyDeal.find(params[:id])
  end
  
  def external_coupons
    @daily_deal = DailyDeal.find(params[:id])
  end
  
  def create_external_coupons
    qty = params[:quantity].to_i
    (1..qty).each do 
      ExternalCoupon.create daily_deal_id: params[:id], code: (0...8).map { (65 + rand(26)).chr }.join, allocated: false
    end
    
    redirect_to :back, notice: "Created #{qty} external coupon codes."
  end
  
  def import_external_coupons
    file_io = params[:file]
    
    
    
    render text: file_io.read
    return
    
    redirect_to :back, notice: "Created #{qty} external coupon codes."
  end
  
  def export_external_coupons
    
  end
  
  def delete_external_coupon
    ExternalCoupon.destroy(params[:external_coupon_id])
    redirect_to :back
  end
  
  def delete_all_external_coupons
    ExternalCoupon.delete_all daily_deal_id: params[:id]
    redirect_to :back
  end
  
  def categories
    @daily_deal = DailyDeal.includes(:categories).find(params[:id])
  end
  
  def create_categories
    DailyDealCategory.delete_all daily_deal_id: params[:id]
    category_ids = params[:category_ids]
    
    category_ids.each do |id|
      DailyDealCategory.create daily_deal_id: params[:id], category_id: id
    end
    
    redirect_to action: 'show', id: params[:id], notice: 'Daily deal was successfully updated.'
  end
  
  private
  
    def daily_deal_params
      params.require(:daily_deal).permit!
    end
  
end
