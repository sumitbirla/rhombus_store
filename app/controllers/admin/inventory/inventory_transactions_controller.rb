class Admin::Inventory::InventoryTransactionsController < Admin::BaseController
  
  def index
    authorize InventoryTransaction.new
    @transactions = InventoryTransaction.includes(:user, :items)
                                        .order(created_at: :desc)
                                        .paginate(page: params[:page], per_page: @per_page)
  end
  
  def new
    @transaction = authorize InventoryTransaction.new( 
                      user_id: session[:user_id], 
                      shipment_id: params[:shipment_id],
                      purchase_order_id: params[:purchase_order_id] )
                      
    unless @transaction.purchase_order_id.nil?
      po = PurchaseOrder.find(@transaction.purchase_order_id)
      po.items.each { |i| @transaction.items.build(sku: i.sku, quantity: i.quantity) }
    end
                        
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
  
    if @transaction.save
      if @transaction.purchase_order_id
        PurchaseOrder.find(@transaction.purchase_order_id).update_received_counts
        redirect_to admin_inventory_purchase_order_path(@transaction.purchase_order_id)
      
      elsif @transaction.shipment_id
        redirect_to admin_store_shipment_path(@transaction.shipment_id)
      
      else
        redirect_to action: 'index', notice: 'Inventory transaction was successfully created.'
      end
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

    if @transaction.save(validate: false)
      
      if @transaction.purchase_order_id
        PurchaseOrder.find(@transaction.purchase_order_id).update_received_counts
        redirect_to admin_inventory_purchase_order_path(@transaction.purchase_order_id)
      
      elsif @transaction.shipment_id
        redirect_to admin_store_shipment_path(@transaction.shipment_id)
      
      else
        redirect_to action: 'index', notice: 'Transaction was successfully updated.'
      end
      
    else
      render 'edit'
    end
  end
  
  def destroy
    @transaction = authorize InventoryTransaction.find(params[:id])
    @transaction.destroy
    redirect_to :back, notice: 'Transaction has been deleted.'
  end
  
  
  private
  
    def inventory_transaction_params
      params.require(:inventory_transaction).permit!
    end
  
  
end
