class Admin::Inventory::PurchaseOrderItemsController < ApplicationController
  
  def create
    p = Product.find_by(sku: params[:sku])
    
    # does the SKU exist in system?
    if p.nil?
      flash[:notice] = "SKU '#{params[:sku]}' not found."
      return redirect_back(fallback_location: admin_root_path)
    end
    
    # does the PO already have this SKU?
    existing = PurchaseOrderItem.find_by(sku: p.sku, purchase_order_id: params[:purchase_order_id])
    if existing
      flash[:notice] = "SKU '#{params[:sku]}' already exists in purchase order."
      return redirect_back(fallback_location: admin_root_path)
    end
    
    # find info from last time this SKU was ordered
    item = PurchaseOrderItem.new purchase_order_id: params[:purchase_order_id], sku: p.sku, description: p.name
    existing = PurchaseOrderItem.where(sku: p.sku).order('created_at DESC').take
    
    if existing
      item.supplier_code = existing.supplier_code
      item.unit_price = existing.unit_price
      item.quantity = existing.quantity
    end
    
    item.save
    
    redirect_back(fallback_location: admin_root_path)
  end
  

  def destroy
    PurchaseOrderItem.delete(params[:id])
    redirect_back(fallback_location: admin_root_path)
  end
  
end
