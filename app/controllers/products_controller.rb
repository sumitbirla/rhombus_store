class ProductsController < ApplicationController
  
  def show
    @product = StoreCache.product(params[:slug])
    
    if @product.nil?
      flash.now[:error] = "The item you are looking for was not found."
      return render "error_page", status: 404 
    end
  end
  
  def product_landing
    @product = StoreCache.product(params[:slug])
    
    if @product.nil?
      flash.now[:error] = "The item you are looking for was not found."
      return render "error_page", status: 404 
    end
    
    # get list of affiliate for which this product exists
    @affiliates = Affiliate.where(id: AffiliateProduct.where(product_id: @product.id).select(:affiliate_id))
  end
  
  
  def category
    @category = Cache.category(params[:category], :product)
    @products = StoreCache.product_list(params[:category])
  end
  
end
