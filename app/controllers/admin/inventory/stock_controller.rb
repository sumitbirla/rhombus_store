class Admin::Inventory::StockController < Admin::BaseController

  def index
    @products = Product.all.includes(:supplier).where(active: true).order('sku')
    @supplier_products = AffiliateProduct.where(affiliate_id: @products.map { |x| x.primary_supplier_id })
  end

end