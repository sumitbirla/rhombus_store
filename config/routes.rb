Rails.application.routes.draw do
  
  get 'cart/remove/:id' => 'cart#remove'
  post 'cart/update'
  get 'cart/add_deal'
  get 'cart/add'
  post 'cart/applycode'
  get 'cart/checkout'
  get 'cart/review'
  post 'cart/review' => 'cart#submit'
  post 'cart/checkout' => 'cart#checkout_update'
  get 'cart/submitted'
  get 'cart' => 'cart#index'
  get "products/:slug" => 'products#show'
  get 'resize' => 'images#resize'
  get 'images/resize'
  get "paypal_express/checkout"
  get "paypal_express/review"
  get 'barcode' => 'barcode#generate'
  
  # daily deals
  get '/deals/email' =>'daily_deals#email'
  get '/deals/:slug' => 'daily_deals#show'
  get '/deals' => 'daily_deals#index'
  
  # affiliate products
  get '/ap/:affiliate_slug/:product_slug' => 'affiliate_products#show'
  get '/ap/:affiliate_slug' => 'affiliate_products#index'
  
  
  namespace :account do
    resources :orders
    resources :vouchers
  end
  
  
  
  namespace :admin do 
    
    namespace :system do 
      resources :affiliates do
        member do
          get 'products' => 'affiliates#products'
          post 'products_remove' => 'affiliates#remove_products'
          post 'products' => 'affiliates#create_products'
        end
      end
    end
    
    namespace :inventory do
      resources :sublocations
      resources :stock
      resources :purchase_orders do
        member do
          get 'items' => 'purchase_orders#items'
          post 'items' => 'purchase_orders#update_items'
          get 'receiving' => 'purchase_orders#receiving'
          post 'items' => 'purchase_orders#update_items'
          post 'receiving' => 'purchase_orders#update_receiving'
          get 'print'
        end
      end
      resources :purchase_order_items
      resources :inventory_transactions
    end

    # Store Routes
    namespace :store do

      get 'reports/product_sales'
      get 'reports/daily_sales'
      get 'reports/monthly_sales'
      get 'reports/pending_fulfillment'
      get 'reports' => 'reports#index'

      get 'shipments_batch' => 'shipments#batch'
      get 'shipments/choose_order'
      post 'shipments_update_status' => 'shipments#update_status'
      post 'shipments_packing_slip_batch' => 'shipments#packing_slip_batch'
      post 'shipments_invoice_batch' => 'shipments#invoice_batch'
      get 'shipments/product_labels'
      
      
      get 'products/adjust_prices'
      post 'products/adjust_prices' => 'products#update_prices'

			get 'easy_post' => 'easy_post#index'
      patch 'easy_post' => 'easy_post#rates'
      get 'easy_post_label' => 'easy_post#label'
      
      post 'orders_batch_ship' => 'orders#batch_ship'
      post 'orders_update_status' => 'orders#update_status'
      post 'orders_print_receipts' => 'orders#print_receipts'
      post 'orders_address_label' => 'orders#address_label'
      post 'orders_send_confirmation' => 'orders#send_confirmation'
      post 'orders_create_shipment' => 'orders#create_shipment'
      
      
      get 'products/item_info' => 'products#item_info'
      
      resources :brands
      resources :products do
        member do
          get 'pictures' 
          get 'categories'
          get 'attributes'
          get 'coupons'
          get 'clone'
          post 'categories' => 'products#create_categories'
          post 'attributes' => 'products#create_attributes'
        end
      end
      resources :orders do
        member do
          resources :items
          resources :deal_items
          get 'resend_email'
          get 'product_labels'
          get 'print_shipping_label'
          get 'receipt'
          get 'clone'
        end
      end
      resources :coupons
      resources :shipments do
        member do
          get 'label_image'
          get 'label'
          get 'print'
          get 'packing_slip'
          get 'invoice'
          get 'void_label'
          get 'email_confirmation'
          get 'create_payment'
        end
      end
      resources :tax_rates
      resources :vouchers do 
        member do
         get 'issue' 
        end
      end
      resources :voucher_groups do
        post 'vouchers' => 'voucher_groups#create_vouchers'
      end
      resources :invoice_images
      resources :shipping_options
      resources :upc
      resources :affiliate_products
      resources :label_sheets
      resources :label_areas

      resources :daily_deals do
        member do
          get 'orders'
          get 'pictures' 
          get 'categories' 
          get 'coupons' 
          get 'items' 
          post 'items' => 'daily_deals#update_items'
          get 'locations'
          get 'external_coupons'
          post 'categories' => 'daily_deals#create_categories'
          post 'coupons' => 'daily_deals#create_coupon'
          post 'create_external_coupons' => 'daily_deals#create_external_coupons'
          post 'import_external_coupons' => 'daily_deals#import_external_coupons'
          get 'delete_external_coupon' => 'daily_deals#delete_external_coupon'
          get 'delete_all_external_coupons' => 'daily_deals#delete_all_external_coupons'
          get 'export_external_coupons' => 'daily_deals#export_external_coupons'
        end
      end

    end
      
  end
  
end
