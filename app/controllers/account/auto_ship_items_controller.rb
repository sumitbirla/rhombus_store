class Account::AutoShipItemsController < Account::BaseController
  
  def index
    @autoship_items = AutoShipItem.where(user_id: session[:user_id]).order(created_at: :desc)
  end
  
  def update
    
  end
  
end
