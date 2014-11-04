class Admin::Store::ProductsController < Admin::BaseController
  
  def index
    @products = Product.includes(:brand).order(:title).page(params[:page])
    @products = @products.where("title LIKE '%#{params[:q]}%' OR sku = '#{params[:q]}'") unless params[:q].nil?
  end

  def new
    @product = Product.new name: 'New product'
    render 'edit'
  end

  def create
    @product = Product.new(product_params)
    
    if @product.save
      redirect_to action: 'index', notice: 'Product was successfully created.'
    else
      render 'edit'
    end
  end

  def show
    @product = Product.includes(:pictures, pattributes: :cms_attribute).find(params[:id])
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    
    if @product.update(product_params)
      Rails.cache.delete @product
      redirect_to action: 'show', id: params[:id], notice: 'Product was successfully updated.'
    else
      render 'edit'
    end
  end

  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    
    Rails.cache.delete @product
    redirect_to action: 'index', notice: 'Product has been deleted.'
  end
  
  def pictures
    @product = Product.find(params[:id])
  end
  
  def coupons
    @product = Product.find(params[:id])
  end
  
  def categories
    @product = Product.find(params[:id])
  end
  
  def create_categories
    @product = Product.find(params[:id])
    ProductCategory.delete_all product_id: @product.id
    category_ids = params[:category_ids]
    
    category_ids.each do |id|
      ProductCategory.create product_id: @product.id, category_id: id
    end
    
    Rails.cache.delete @product
    redirect_to action: 'show', id: @product.id, notice: 'Product was successfully updated.'
  end
  
  def attributes
    @product = Product.find(params[:id])
  end
  
  def create_attributes
    
    @product = Product.find(params[:id])
    attr_list = Attribute.where(entity_type: :product)
    
    attr_list.each do |attr|
      
      prod_attr = @product.pattributes.find { |a| a.attribute_id == attr.id }
      attr_id = "attr-#{attr.id}"
      
      # DELETE
      if params[attr_id].blank?  
        prod_attr.destroy if prod_attr
        next
      end
      
      #ADD
      unless prod_attr
        prod_attr = ProductAttribute.new product_id: @product.id, attribute_id: attr.id
      end
      
      prod_attr.value = params[attr_id]
      prod_attr.save
      
    end
    
    Rails.cache.delete @product
    redirect_to action: 'show', id: params[:id], notice: 'Product was successfully updated.'
  end
  
  
  def adjust_prices
    @products = Product.all
  end
  
  
  def update_prices
    
    @products = Product.all
    
    params.each do |key, val|
      
      tokens = key.split('-')
      next unless ['retail', 'dealer'].include?(tokens[0])
      
      value = val.to_d
      product_id = tokens[1].to_i
      product = @products.find { |p| p.id == product_id }
      
      product.update_attribute(:price, value) if tokens[0] == 'retail' && product.price != value
      product.update_attribute(:dealer_price, value) if tokens[0] == 'dealer'&& product.dealer_price != value
      
    end
    
    flash[:notice] = "Prices have been updated"
    redirect_to action: 'index'
  end
  
  
  def item_info
    p = Product.find_by(sku: params[:sku])
    if p
      return render json: { status: 'ok', product_id: p.id, description: p.title, price: p.price, dealer_price: p.dealer_price }
    else
      sku, affiliate_code, variant = params[:sku].split('-')
      p = Product.find_by(sku: sku)
      aff = Affiliate.find_by(code: affiliate_code)
      
      unless p.nil? || aff.nil?
        return render json: { status: 'ok', product_id: p.id, affiliate_id: aff.id, variation: variant, description: p.title, price: p.price, dealer_price: p.dealer_price }
      end
    end
    
    render json: { status: 'not found' }
  end
  
  
  private
  
    def product_params
      params.require(:product).permit(:name, :group, :type, :title, :brand_id, :product_type,
      :slug, :price, :msrp, :retail_map, :special_price, :dealer_price, :free_shipping, :tax_exempt, :hidden, :featured,
      :require_image_upload, :option_title, :option_sort, :short_description, :long_description,
      :sku, :fulfiller_id, :primary_supplier_id, :warranty, :keywords, :country_of_origin, :minimum_order_quantity,
      :shipping_lead_time, :item_availability, :item_length, :item_width, :item_height, :item_weight, :case_length,
      :case_width, :case_height, :case_weight, :case_quantity, :committed, :low_threshold)
    end
  
end
