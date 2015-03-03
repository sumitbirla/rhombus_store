class AffiliateProductsController < ApplicationController
  
  # GET /ap/:affiliate-slug
  def index
    @affiliate_products = StoreCache.all_affiliate_products(params[:affiliate_slug])
  end
  
  # GET /ap/:affiliate-slug/:product-slug
  def show
    @affiliate_product = StoreCache.affiliate_product(params[:affiliate_slug], params[:product_slug])
  end
  
end
