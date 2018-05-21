class AffiliateProductsController < ApplicationController
  
  # GET /ap/:affiliate-slug
  def index
    aff = Affiliate.find_by(slug: params[:affiliate_slug])
    @affiliate_products = AffiliateProduct.joins(:product)
                    .includes(:product, [product: :pictures])
                    .where(affiliate_id: aff.id)
                    .where("store_products.active=1 AND store_products.hidden=0 AND store_products.affiliate_only=1")
                    .order("store_products.option_title")
  end
  
  # GET /ap/:affiliate-slug/:product-slug
  def show
    @affiliate_product = StoreCache.affiliate_product(params[:affiliate_slug], params[:product_slug])
  end
  
end
