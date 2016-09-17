class Admin::Inventory::PurchaseOrdersController < Admin::BaseController
  # ['new', 'release', 'change_order', 'received', 'cancelled', 'closed']
  
  def index
    @purchase_orders = PurchaseOrder.includes(:items)
                                    .joins(:supplier)
                                    .order(sort_column + " " + sort_direction)
                                    .page(params[:page])
                                    
    @purchase_orders = @purchase_orders.where(status: params[:status]) unless params[:status].blank?                             
    @purchase_orders = @purchase_orders.where(id: params[:q]) unless params[:q].nil?
  end

  def new
    @purchase_order = PurchaseOrder.new(issue_date: Date.today, due_date: Date.today + 1.week, status: 'new')
    20.times { @purchase_order.items.build }
    render 'edit'
  end

  def create
    @purchase_order = PurchaseOrder.new(purchase_order_params)
    
    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - @purchase_order.items.length + 10 
      count.times { @purchase_order.items.build }
      return render 'edit'
    end
    
    if @purchase_order.save
      flash[:notice] = 'PurchaseOrder was successfully created.'
      redirect_to admin_inventory_purchase_order_path(@purchase_order)
    else
      render 'edit'
    end
  end

  def show
    @purchase_order = PurchaseOrder.includes(:inventory_transactions, [inventory_transactions: :items]).find(params[:id])
  end

  def edit
    @purchase_order = PurchaseOrder.find(params[:id])
    5.times { @purchase_order.items.build }
  end

  def update
    @purchase_order = PurchaseOrder.find(params[:id])
    @purchase_order.assign_attributes(purchase_order_params)
    
    unless params[:add_more_items].blank?
      count = params[:add_more_items].to_i - @purchase_order.items.length + 5 
      count.times { @purchase_order.items.build }
      return render 'edit'
    end
    
    if @purchase_order.save
      flash[:notice] = 'PurchaseOrder was successfully updated.'
      redirect_to admin_inventory_purchase_order_path(@purchase_order)
    else
      render 'edit'
    end
  end

  def destroy
    @purchase_order = PurchaseOrder.find(params[:id])
    @purchase_order.destroy
    
    redirect_to action: 'index', notice: 'PurchaseOrder has been deleted.'
  end
  
  def items
    @purchase_order = PurchaseOrder.find(params[:id])
  end
  
  def update_items
    
    @purchase_order = PurchaseOrder.includes(:items).find(params[:id])
    
    params.each do |key, val|
      
      tokens = key.split('-')
      next unless tokens.length == 2 || val.blank?
      
      item_number = tokens[1].to_i
      item = @purchase_order.items.find { |i| i.id == item_number }
      
      case tokens[0]
      when 'qty'
        item.quantity = val.to_i
      when 'desc'
        item.description = val
      when 'price'
        item.unit_price = val.to_d
      when 'sup'
        item.supplier_code = val
      when 'recv'
        item.quantity_received += val.to_i
      end
      
      item.save
    end
    
    redirect_to admin_inventory_purchase_order_path(@purchase_order)
  end
  
  def receiving
    @purchase_order = PurchaseOrder.find(params[:id])
  end
  
  def update_receiving
    @purchase_order = PurchaseOrder.find(params[:id])
    transaction_id = Adjustment.maximum('transaction_id') || 0
    transaction_id += 1

    update_count = 0

    PurchaseOrder.transaction do
      params.each do |key, val|
        tokens = key.split('-')
        
        next unless tokens.length == 2
        next unless tokens[0] == 'recv'
        next if val.blank?
      
        qty = val.to_i
        next if qty == 0
      
        item_number = tokens[1].to_i
        item = @purchase_order.items.find { |i| i.id == item_number }
      
        item.increment!(:quantity_received, val.to_i)
        Adjustment.create transaction_id: transaction_id, user_id: current_user.id,
                 purchase_order_id: @purchase_order.id, sku: item.sku, quantity: qty
                 
        update_count += 1
      end
    end

    if update_count == 0
      flash[:notice] = 'No updates made.'
      return redirect_to :back
    end
    
    # check if purchase order status needs to be updated
    if @purchase_order.items.any? { |i| i.quantity_received < i.quantity }
      @purchase_order.status = 'partially_received'
    else
      @purchase_order.status = 'received'
    end
    @purchase_order.save
    
    
    flash[:notice] = "#{update_count} items updated. Inventory transaction ID is #{transaction_id}."
    redirect_to admin_inventory_purchase_order_path(@purchase_order)
  end
  
  def print
    @purchase_order = PurchaseOrder.find(params[:id])
    render 'print', layout: nil
  end
  
  
  private
  
    def purchase_order_params
      params.require(:purchase_order).permit!
    end
  
    def sort_column
      params[:sort] || "id"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end
end
