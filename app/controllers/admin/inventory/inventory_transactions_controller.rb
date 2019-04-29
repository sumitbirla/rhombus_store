class Admin::Inventory::InventoryTransactionsController < Admin::BaseController
  
  def index
    authorize InventoryTransaction.new
    @transactions = InventoryTransaction.includes(:items, :affiliate)
                                        .order(created_at: :desc)
                                        .paginate(page: params[:page], per_page: @per_page)
  end
  
  def new
    @transaction = authorize InventoryTransaction.new         
    10.times { @transaction.items.build }
		
    render 'edit'
  end
  
  def create
    @transaction = authorize InventoryTransaction.new(inventory_transaction_params)

    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - @transaction.items.length + 5 
      count.times { @transaction.items.build }
      return render 'edit'
    end
  
		@transaction.responsible_party = current_user.name
    if @transaction.save
      redirect_to action: 'index', notice: 'Inventory transaction was successfully created.'
    else
      5.times { @transaction.items.build }
      render 'edit'
    end
  end
  
  def edit
    @transaction = authorize InventoryTransaction.find(params[:id])
    5.times { @transaction.items.build }
  end
  
  def update
    @transaction = authorize InventoryTransaction.find(params[:id])
    item_count = @transaction.items.length

    @transaction.assign_attributes(inventory_transaction_params)
    
    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - item_count + 5 
      count.times { @transaction.items.build }
      return render 'edit'
    end

    if @transaction.save
			redirect_to action: 'index', notice: 'Transaction was successfully updated.'
    else
      render 'edit'
    end
  end
  
  def destroy
    @transaction = authorize InventoryTransaction.find(params[:id])
    @transaction.destroy

    flash[:success] = 'Transaction has been deleted.'
    redirect_back(fallback_location: admin_root_path)
  end
  
  
  private
  
    def inventory_transaction_params
      params.require(:inventory_transaction).permit!
    end
  
  
end
