class ProductsController < ApplicationController
  
  def show
    @product = StoreCache.product(params[:slug]) or not_found
  end
  
  def product_landing
    @product = StoreCache.product(params[:slug]) or not_found

    # get list of affiliate for which this product exists
    @affiliates = Affiliate.where(id: AffiliateProduct.where(product_id: @product.id).select(:affiliate_id))
  end
  
  
  def category
    @category = Cache.category(params[:category], :product)
    @products = StoreCache.product_list(params[:category])
  end
  
end
