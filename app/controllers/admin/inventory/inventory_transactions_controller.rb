class Admin::Inventory::InventoryTransactionsController < Admin::BaseController

  def index
    @transactions = InventoryTransaction.includes(:user).page(params[:page]).order('timestamp DESC')
  end
  
  def show
    @transaction = InventoryTransaction.find(params[:id])
  end
  
  def new
    @transaction = InventoryTransaction.new
    10.times { @transaction.items.build }
    
    render 'edit'
  end
  
  def create
    @transaction = InventoryTransaction.new(inventory_transaction_params)
    @transaction.user_id = session[:user_id]
    @transaction.timestamp = DateTime.now
    
    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - @transaction.items.length + 5 
      count.times { @transaction.items.build }
      return render 'edit'
    end
  
    if @transaction.save
      redirect_to action: 'index', notice: 'Transaction was successfully saved.'
    else
      render 'edit'
    end
  end
  
  def edit
    @transaction = InventoryTransaction.find(params[:id])
    2.times { @transaction.items.build }
  end
  
  def update
    @transaction = InventoryTransaction.find(params[:id])
    item_count = @transaction.items.length

    @transaction.assign_attributes(inventory_transaction_params)
    
    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - item_count + 5 
      count.times { @transaction.items.build }
      return render 'edit'
    end

    if @transaction.save
      redirect_to action: 'show', id: @transaction.id, notice: 'Transaction was successfully updated.'
    else
      render 'edit'
    end
  end
  
  def destroy
    InventoryTransaction.find(params[:id]).destroy
    redirect_to :back
  end
  
  
  private
  
  def inventory_transaction_params
    params.require(:inventory_transaction).permit!
  end

end
