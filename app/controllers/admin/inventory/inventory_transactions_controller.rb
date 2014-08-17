class Admin::Inventory::InventoryTransactionsController < Admin::BaseController

  def index
    @transactions = InventoryTransaction.includes(:user).page(params[:page]).order('timestamp DESC')
  end

end
