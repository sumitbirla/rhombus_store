class Admin::Store::ProductsController < Admin::BaseController
  
  def index
    authorize Product.new
    
    q = params[:q]
    @products = Product.order(sort_column + " " + sort_direction)
    if params[:status].blank?
      @active = true
    else
      @active = (params[:status] == "active")
    end
    
    unless q.nil?
      @products = @products.where("name LIKE '%#{q}%' OR item_number = ? OR SKU = ? OR upc = ?", q, q, q) 
    else
      @products = @products.where(active: @active)
      @products = @products.where(brand_id: (params[:brand_id] == "white-label" ? nil : params[:brand_id])) unless params[:brand_id].blank?
    end
      
    respond_to do |format|
      format.html  { @products = @products.paginate(page: params[:page], per_page: @per_page) }
      format.csv { send_data Product.to_csv(@products.includes(:pictures, :extra_properties)) }
    end
  end

  def new
    @product = authorize Product.new(name: 'New product', fulfiller_id: Cache.setting('eCommerce', 'Default Fulfiller ID'))
    render 'edit'
  end

  def create
    @product = authorize Product.new(product_params)
    
    if @product.save
      redirect_to action: 'show', id: @product.id, notice: 'Product was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @product = authorize Product.find(params[:id])
  end

  def edit
    @product = authorize Product.find(params[:id])
  end

  def update
    @product = authorize Product.find(params[:id])

    if @product.update(product_params)
      Rails.cache.delete @product
      Rails.cache.delete("featured-product")
      redirect_to action: 'show', id: params[:id], notice: 'Product was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @product = authorize Product.find(params[:id])
		
		begin
    	@product.destroy
    	Rails.cache.delete @product
			flash[:success] = 'Product has been deleted.'
		rescue => e
			flash[:error] = e.message
		end
		
		redirect_back(fallback_location: admin_root_path)
  end
  
  def pictures
    @product = Product.find(params[:id])
    authorize @product, :show?
  end
  
  def coupons
    @product = Product.find(params[:id])
    authorize @product, :show?
  end
  
  def categories
    @product = Product.find(params[:id])
    authorize @product, :show?
  end
  
  def create_categories
    @product = Product.find(params[:id])
    authorize @product, :update?
    
    ProductCategory.where(product_id: @product.id).delete_all
    category_ids = params[:category_ids] || []
    
    category_ids.each do |id|
      ProductCategory.create product_id: @product.id, category_id: id
    end
    
    Rails.cache.delete @product
    redirect_to action: 'show', id: @product.id, notice: 'Product was successfully updated.'
  end
  
  def catalogs
    @product = Product.find(params[:id])
    authorize @product, :show?
  end
  
  def create_catalogs
    @product = Product.find(params[:id])
    authorize @product, :update?
    
    ProductCatalog.where(product_id: @product.id).delete_all
    catalogs = params[:catalogs] || []
    catalogs.each do |c| 
      ProductCatalog.create(product_id: @product.id, 
                            catalog_id: c[:id],
                            standard_price: c[:standard_price],
                            promotional_price: c[:promotional_price])
    end
    
    Rails.cache.delete @product
    redirect_to action: 'show', id: @product.id, notice: 'Product was successfully updated.'
  end
  
  def extra_properties
    @product = Product.find(params[:id])
    authorize @product, :show?
    5.times { @product.extra_properties.build }
  end
  
  def label_elements
    @product = Product.find(params[:id])
    authorize @product, :show?
  end
	
  def shipping_rates
    @product = Product.find(params[:id])
		authorize @product, :show?
		
		3.times { @product.shipping_rates.build }
  end
  
  def adjust_prices
    authorize Product, :update?
    @products = Product.where(active: true)
  end
  
  
  def update_prices
    authorize Product, :update?
    @products = Product.all
    
    params.each do |key, val|
      
      tokens = key.split('-')
      next unless [ 'web', 'distributor', 'retailer', 'msrp', 'map'].include?(tokens[0])
      
      value = val.blank? ? nil : val.to_d
      product_id = tokens[1].to_i
      product = @products.find { |p| p.id == product_id }
      
      product.update_attribute(:price, value) if tokens[0] == 'web' unless product.price == value
      product.update_attribute(:retail_map, value) if tokens[0] == 'map' unless product.retail_map == value
      product.update_attribute(:msrp, value) if tokens[0] == 'msrp' unless product.msrp == value
      
    end
    
    flash[:notice] = "Prices have been updated"
    redirect_back(fallback_location: admin_root_path)
  end
  
  
  def item_info
    sku = params[:sku]
    aff_id = params[:affiliate_id]
    
    # handle daily deals first
    if sku.starts_with?('DEAL')
      dd = DailyDeal.find_by(id: sku.sub("DEAL", "").to_i)
      render json: { status: 'not found' } if dd.nil?
      
      return render json: { status: 'ok', 
														item_number: sku,
                            daily_deal_id: dd.id, 
                            description: dd.title, 
                            price: dd.deal_price, 
                            dealer_price: dd.deal_price,
                            moc: 1 }
    end
       
    p = Product.find_by("item_number = ? OR upc = ?", sku, sku)
    return render json: { status: 'not found' } if p.nil?
    
    ap = AffiliateProduct.find_by(affiliate_id: aff_id, product_id: p.id) unless aff_id.blank?
  
    render json: { status: 'ok', 
                   product_id: p.id,
                   item_number: (ap ? (ap.item_number || p.item_number) : p.item_number),
									 sku: p.sku,
									 upc: p.upc, 
                   description: (ap ? (ap.description.presence || p.name_with_option) : p.name_with_option), 
                   price: (ap ? ap.price : p.price),
                   moc: (ap ? ap.minimum_order_quantity : 1) }
  end
  
  
  def clone
    @product = Product.find(params[:id]).dup
    @product.slug += "-clone"
    render 'edit'
  end
	
	# GET /admin/store/products/:id/template
	def template
    @product = Product.find(params[:id])
    authorize @product, :update?
	end
	
	# POST /admin/store/products/:id/template
	def apply_template
		@product = Product.find(params[:id])
		authorize @product, :update?
		
		if params[:field_names].nil?
			flash[:info] = "No fields selected.  Please select one or more fields to update."
			return redirect_back(fallback_location: admin_root_path)
		end
		
		new_values = @product.attributes.select { |k, v| params[:field_names].include?(k) }
		count = Product.where(template_product_id: @product.id).update_all(new_values)
		
		if count > 0
			flash[:info] = "#{count} items (#{params[:field_names].length} fields) have been updated."
			redirect_to admin_store_product_path(params[:id])
		else
			flash[:info] = "No records updated."
			render 'template'
		end
	end
  
  
  private
  
    def product_params
      params.require(:product).permit!
    end
    
    def sort_column
      params[:sort] || "title"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
  
end
