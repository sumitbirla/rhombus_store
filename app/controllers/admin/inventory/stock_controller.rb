class Admin::Inventory::StockController < Admin::BaseController

  def index
    @products = Product.all.includes(:supplier).order('sku')
  end

end