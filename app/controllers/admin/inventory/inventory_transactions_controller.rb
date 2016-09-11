class Admin::Inventory::InventoryTransactionsController < Admin::BaseController
  
  def index
    @transactions = InventoryTransaction.includes(:user, :items)
                                        .order(created_at: :desc)
                                        .page(params[:page])
  end
  
  def new
    @transaction = InventoryTransaction.new(user_id: session[:user_id], entity_type: 'Manual')
    10.times { @transaction.items.build }
    render 'edit'
  end
  
  def create
    @transaction = InventoryTransaction.new(inventory_transaction_params)

    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - @transaction.items.length + 5 
      count.times { @transaction.items.build }
      return render 'edit'
    end
  
    if @transaction.save
      redirect_to action: 'index', notice: 'Inventory transaction was successfully created.'
    else
      5.times { @transaction.items.build }
      render 'edit'
    end
  end
  
  def edit
    @transaction = InventoryTransaction.find(params[:id])
    5.times { @transaction.items.build }
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

    if @transaction.save(validate: false)
      redirect_to action: 'index', notice: 'Transaction was successfully updated.'
    else
      render 'edit'
    end
  end
  
  def destroy
    @transaction = InventoryTransaction.find(params[:id])
    @transaction.destroy
    redirect_to action: 'index', notice: 'Transaction has been deleted.'
  end
  
  
  private
  
    def inventory_transaction_params
      params.require(:inventory_transaction).permit!
    end
  
  
end
