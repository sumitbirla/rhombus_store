class Account::OrdersController < Account::BaseController

  def index
    @orders = Order.includes(:shipments, items: { product: :pictures })
                   .where("user_id = ? AND status != 'in cart'", session[:user_id])
                   .order(submitted: :desc)
                   .paginate(params[:page])
     
     q = params[:q]
     unless q.blank?
       @orders = @orders.where("billing_name LIKE '%#{q}%' OR id = #{q} OR external_order_id = '#{q}' OR external_order_name LIKE '%#{q}%' OR notify_email = '#{q}' OR contact_phone = '#{q}'")
     end   
  end

  def show
    @order = Order.find_by(user_id: current_user.id, id: params[:id])
  end

end
