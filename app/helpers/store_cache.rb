module StoreCache
  
  def self.new_orders_count
    Rails.cache.fetch(:new_orders_count, expires_in: 2.minutes) do 
      Order.where(status: ['awaiting_shipment']).count
    end
  end
  
  def self.new_purchase_orders_count
    Rails.cache.fetch(:new_po_count, expires_in: 2.minutes) do 
      PurchaseOrder.where(status: ['released']).count
    end
  end
  
  def self.pending_shipments_count
    Rails.cache.fetch(:pending_shipments_count, expires_in: 2.minutes) do 
      Shipment.where(status: 'pending').count
    end
  end
    
  def self.product(slug) 
    Rails.cache.fetch("product:#{slug}") do 
      Product.includes(:categories, :extra_properties, :brand, :pictures, :comments).find_by(slug: slug, active: true)
    end
  end
  
  def self.featured_product 
    Rails.cache.fetch("featured-product") do 
      Product.includes(:brand, :pictures, :comments).where(featured: true, active: true).first
    end
  end
  
  
  def self.product_list(category_slug)
    Rails.cache.fetch("product-list:#{category_slug}") do
      c = Category.find_by(slug: category_slug, entity_type: :product)
      Product.where(active: true, id: ProductCategory.where(category_id: c.id).pluck(:product_id)).load
    end
  end
  
  def self.all_affiliate_products(slug)
    Rails.cache.fetch("ap-list:#{slug}", force: true) do
      aff = Affiliate.find_by(slug: slug)
      AffiliateProduct.joins(:product)
                      .includes(:product, [product: :pictures])
                      .order("store_products.title")
                      .where(affiliate_id: aff.id)
                      .where("store_products.active=1 AND store_products.hidden=0 AND store_products.affiliate_only=1").load
    end
  end
  
  def self.affiliate_products(affiliate_slug, category_slug)
    Rails.cache.fetch("affiliate-products-#{affiliate_slug}-#{category_slug}") do
      
      cat = Category.find_by(slug: category_slug, entity_type: :product)
      aff = Affiliate.find_by(slug: affiliate_slug)

      new_list = []
      ap_list = AffiliateProduct.joins(:product)
                                .includes(:product, [product: :product_categories])
                                .where(affiliate_id: aff.id)
                                .where("store_products.active=1 AND store_products.hidden=0 AND store_products.affiliate_only=1")
      
      ap_list.each do |ap|
        new_list << ap if ap.product.product_categories.any? { |pc| pc.category_id == cat.id }
      end
      
      new_list
    end
  end
  
  def self.affiliate_product(affiliate, product_slug)
    affiliate = Affiliate.find_by(slug: affiliate) if affiliate.class.name == "String"
    
    Rails.cache.fetch("ap:#{affiliate.slug}:#{product_slug}") do
      AffiliateProduct
            .includes(:product, [product: [:pictures, :extra_properties]])
            .find_by(affiliate_id: affiliate.id, product_id: Product.select(:id).where(slug: product_slug))
    end
  end
  
  def self.non_affiliate_products
    Rails.cache.fetch("non-affiliate-products") do
      Product
          .includes(:pictures, :extra_properties, :categories)
          .where(affiliate_only: false, hidden: false, active: true)
    end
  end
  
  
  # Daily deals
  
  def self.featured_deal
    Rails.cache.fetch("featured-deal") do 
      DailyDeal.includes(:pictures)
                .where(active: true)
                .where("start_time < NOW()")
                .where("end_time > NOW()")
                .order("start_time DESC").first
    end
  end
  
  def self.active_deals
    Rails.cache.fetch("active-deals") do 
      DailyDeal.where(active: true)
                    .where("start_time < NOW()")
                    .where("end_time > NOW()")
                    .order("start_time DESC")
    end
  end
  
end