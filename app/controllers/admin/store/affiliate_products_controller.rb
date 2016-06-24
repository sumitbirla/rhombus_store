class Admin::Store::AffiliateProductsController < Admin::BaseController
  
  def create
    begin
      ap = AffiliateProduct.new(affiliate_product_params)
      ap.save!
    rescue => e
      flash[:error] = e.message
    end
    
    redirect_to :back
  end
  
  def edit
    @affiliate_product = AffiliateProduct.find(params[:id])
  end

  def update
    @affiliate_product = AffiliateProduct.find(params[:id])
    
    if @affiliate_product.update(affiliate_product_params)
      redirect_to admin_store_affiliate_products_path(affiliate_id: @affiliate_product.affiliate_id)
    else
      render 'edit'
    end
  end
  
  def destroy
    @affiliate_product = AffiliateProduct.find(params[:id])
    @affiliate_product.destroy

    redirect_to :back
  end
  
  
  private
  
    def affiliate_product_params
      params.require(:affiliate_product).permit!
    end
end
