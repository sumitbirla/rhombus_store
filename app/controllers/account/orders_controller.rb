class Account::OrdersController < Account::BaseController

  def index
    @orders = Order.includes(:items).where("user_id = ? AND status != 'in cart'", session[:user_id]).order('submitted DESC')
  end

  def show
    @order = Order.find_by(user_id: current_user.id, id: params[:id])
  end

end
