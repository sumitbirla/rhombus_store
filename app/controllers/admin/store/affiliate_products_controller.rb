class Admin::Store::AffiliateProductsController < Admin::BaseController
  
  def edit
    @affiliate_product = AffiliateProduct.find(params[:id])
  end

  def update
    @affiliate_product = AffiliateProduct.find(params[:id])
    
    if @affiliate_product.update(affiliate_product_params)
      redirect_to products_admin_system_affiliate_path(@affiliate_product.affiliate_id)
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
      params.require(:affiliate_product).permit(:title, :description, :price, :data)
    end
end
