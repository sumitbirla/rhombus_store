class Admin::Inventory::StockController < Admin::BaseController
  
  def index
    @skus = Sku.includes(:fulfiller, :supplier).page(params[:page]).order('code')
  end

end
