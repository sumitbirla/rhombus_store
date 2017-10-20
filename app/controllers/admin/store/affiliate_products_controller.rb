class Admin::Store::AffiliateProductsController < Admin::BaseController
  
  def new
    authorize AffiliateProduct
    @affiliate_product = AffiliateProduct.new(affiliate_id: params[:affiliate_id])
    render 'edit'
  end
  
  def create
    begin
      ap = authorize AffiliateProduct.new(affiliate_product_params)
      ap.save!
    rescue => e
      flash[:error] = e.message
      redirect_to :back
    end
    
    redirect_to admin_system_affiliate_path(ap.affiliate_id, q: :products)
  end
  
  def edit
    @affiliate_product = authorize AffiliateProduct.find(params[:id])
  end

  def update
    @affiliate_product = authorize AffiliateProduct.find(params[:id])
    
    if @affiliate_product.update(affiliate_product_params)
      redirect_to admin_system_affiliate_path(@affiliate_product.affiliate_id, q: :products)
    else
      render 'edit'
    end
  end
  
  def destroy
    @affiliate_product = authorize AffiliateProduct.find(params[:id])
    @affiliate_product.destroy

    redirect_to :back
  end
  
  
  private
  
    def affiliate_product_params
      params.require(:affiliate_product).permit!
    end
end
