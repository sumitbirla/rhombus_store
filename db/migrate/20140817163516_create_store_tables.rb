class CreateStoreTables < ActiveRecord::Migration
  def change
    
    create_table "store_affiliate_products", force: true do |t|
      t.integer  "affiliate_id",                          null: false
      t.integer  "product_id",                            null: false
      t.decimal  "price",        precision: 10, scale: 2
      t.string   "title"
      t.text     "description"
      t.string   "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_affiliate_products", ["affiliate_id"], name: "index_affiliate_products_on_affiliate_id", using: :btree
    add_index "store_affiliate_products", ["product_id"], name: "index_affiliate_products_on_product_id", using: :btree
    
    create_table "store_brands", force: true do |t|
      t.string   "name"
      t.string   "website"
      t.string   "logo"
      t.text     "about"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "store_coupons", force: true do |t|
      t.string   "code",                                      null: false
      t.text     "description"
      t.integer  "product_id"
      t.integer  "daily_deal_id"
      t.boolean  "free_shipping"
      t.decimal  "discount_amount",  precision: 10, scale: 2
      t.decimal  "discount_percent", precision: 5,  scale: 2
      t.decimal  "min_order_amount", precision: 10, scale: 2
      t.integer  "max_uses"
      t.integer  "max_per_user"
      t.integer  "times_used",                                null: false
      t.datetime "start_time",                                null: false
      t.datetime "expire_time",                               null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_coupons", ["product_id"], name: "index_coupons_on_product_id", using: :btree

    create_table "store_daily_deal_categories", force: true do |t|
      t.integer  "daily_deal_id"
      t.integer  "category_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_daily_deal_categories", ["category_id"], name: "index_daily_deal_categories_on_category_id", using: :btree
    add_index "store_daily_deal_categories", ["daily_deal_id"], name: "index_daily_deal_categories_on_daily_deal_id", using: :btree

    create_table "store_daily_deal_coupons", force: true do |t|
      t.string   "code",                                       null: false
      t.text     "description"
      t.integer  "daily_deal_id",                              null: false
      t.boolean  "free_shipping",                              null: false
      t.boolean  "free_order",                                 null: false
      t.decimal  "discount_amount",   precision: 10, scale: 2
      t.decimal  "discount_percent",  precision: 5,  scale: 2
      t.decimal  "min_order_amount",  precision: 10, scale: 2
      t.integer  "buy_x"
      t.integer  "get_y_free"
      t.integer  "max_uses"
      t.integer  "max_user_per_user"
      t.datetime "start_time"
      t.datetime "expire_time"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_daily_deal_coupons", ["daily_deal_id"], name: "index_daily_deal_coupons_on_daily_deal_id", using: :btree

    create_table "store_daily_deal_items", force: true do |t|
      t.integer  "daily_deal_id",                         null: false
      t.integer  "product_id",                            null: false
      t.decimal  "unit_cost",     precision: 8, scale: 2, null: false
      t.integer  "quantity",                              null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_daily_deal_items", ["daily_deal_id"], name: "index_daily_deal_items_on_daily_deal_id", using: :btree
    add_index "store_daily_deal_items", ["product_id"], name: "index_daily_deal_items_on_product_id", using: :btree

    create_table "store_daily_deal_locations", force: true do |t|
      t.integer  "daily_deal_id", null: false
      t.integer  "location_id",   null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_daily_deal_locations", ["daily_deal_id"], name: "index_daily_deal_locations_on_daily_deal_id", using: :btree
    add_index "store_daily_deal_locations", ["location_id"], name: "index_daily_deal_locations_on_location_id", using: :btree

    create_table "store_daily_deals", force: true do |t|
      t.integer  "region_id",                                                       null: false
      t.integer  "affiliate_id"
      t.decimal  "affiliate_remittance",       precision: 8, scale: 2
      t.boolean  "affiliate_paid",                                                  null: false
      t.string   "deal_type",                                          default: "", null: false
      t.string   "slug",                                                            null: false
      t.string   "title",                                                           null: false
      t.datetime "start_time",                                                      null: false
      t.datetime "end_time",                                                        null: false
      t.datetime "voucher_expiration"
      t.decimal  "original_price",             precision: 8, scale: 2,              null: false
      t.decimal  "deal_price",                 precision: 8, scale: 2,              null: false
      t.decimal  "shipping_cost",              precision: 6, scale: 2
      t.text     "conditions"
      t.text     "description",                                                     null: false
      t.string   "short_tag_line",                                                  null: false
      t.text     "redemption_instructions"
      t.text     "order_specifications"
      t.string   "theme"
      t.integer  "max_sales"
      t.integer  "max_per_user"
      t.integer  "number_sold",                                                     null: false
      t.boolean  "countdown_mode",                                                  null: false
      t.integer  "sales_before_showing_count"
      t.boolean  "active",                                                          null: false
      t.boolean  "featured",                                                        null: false
      t.boolean  "allow_photo_upload",                                              null: false
      t.integer  "facebook_posts",                                                  null: false
      t.integer  "facebook_clicks",                                                 null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_daily_deals", ["affiliate_id"], name: "index_daily_deals_on_affiliate_id", using: :btree
    
    create_table "store_external_coupons", force: true do |t|
      t.integer  "daily_deal_id", null: false
      t.string   "code",          null: false
      t.boolean  "allocated",     null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_external_coupons", ["daily_deal_id"], name: "index_external_coupons_on_daily_deal_id", using: :btree
    
    create_table "store_inventory_transaction_items", force: true do |t|
      t.integer "inventory_transaction_id"
      t.string  "sku"
      t.integer "quantity"
    end

    add_index "store_inventory_transaction_items", ["inventory_transaction_id"], name: "index_inventory_transaction_items_on_inventory_transaction_id", using: :btree

    create_table "store_inventory_transactions", force: true do |t|
      t.integer  "user_id"
      t.integer  "shipment_id"
      t.integer  "purchase_order_id"
      t.integer  "num_items"
      t.datetime "timestamp"
      t.text     "notes"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_inventory_transactions", ["purchase_order_id"], name: "index_inventory_transactions_on_purchase_order_id", using: :btree
    add_index "store_inventory_transactions", ["shipment_id"], name: "index_inventory_transactions_on_shipment_id", using: :btree
    add_index "store_inventory_transactions", ["user_id"], name: "index_inventory_transactions_on_user_id", using: :btree

    create_table "store_invoice_images", force: true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_label_areas", force: true do |t|
      t.integer  "label_sheet_id"
      t.string   "name",                                   null: false
      t.decimal  "top",            precision: 6, scale: 2, null: false
      t.decimal  "left",           precision: 6, scale: 2, null: false
      t.decimal  "width",          precision: 6, scale: 2, null: false
      t.decimal  "height",         precision: 6, scale: 2, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_label_areas", ["label_sheet_id"], name: "index_label_areas_on_label_sheet_id", using: :btree

    create_table "store_label_elements", force: true do |t|
      t.integer  "product_id",                                    null: false
      t.string   "name",                                          null: false
      t.string   "type",                                          null: false
      t.string   "use",                                           null: false
      t.decimal  "top",                  precision: 6,  scale: 2
      t.decimal  "left",                 precision: 6,  scale: 2
      t.decimal  "width",                precision: 6,  scale: 2
      t.decimal  "height",               precision: 6,  scale: 2
      t.string   "background_color"
      t.string   "horizontal_alignment"
      t.string   "vertical_alignment"
      t.decimal  "font_size",            precision: 10, scale: 0
      t.string   "font_color"
      t.string   "font_family"
      t.string   "font_style"
      t.integer  "max_chars"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_label_sheets", force: true do |t|
      t.string   "name",                               null: false
      t.decimal  "width",      precision: 6, scale: 2, null: false
      t.decimal  "height",     precision: 6, scale: 2, null: false
      t.integer  "dpi",                                null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "store_order_history", force: true do |t|
      t.integer  "order_id",                                          null: false
      t.integer  "user_id"
      t.string   "event_type",                           default: "", null: false
      t.decimal  "amount",      precision: 10, scale: 2
      t.string   "system_name",                                       null: false
      t.string   "identifier"
      t.string   "comment"
      t.binary   "data1"
      t.binary   "data2"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_order_history", ["order_id"], name: "index_order_histories_on_order_id", using: :btree

    create_table "store_order_items", force: true do |t|
      t.integer  "order_id",                                                null: false
      t.integer  "product_id",                                              null: false
      t.integer  "affiliate_id"
      t.string   "external_id"
      t.string   "variation"
      t.integer  "quantity",                                                null: false
      t.decimal  "unit_price",                     precision: 10, scale: 2, null: false
      t.string   "item_id",             limit: 32,                          null: false
      t.string   "item_description",                                        null: false
      t.string   "uploaded_file"
      t.string   "upload_file_preview"
      t.integer  "start_x_percent"
      t.integer  "start_y_percent"
      t.integer  "width_percent"
      t.integer  "height_percent"
      t.string   "custom_text"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_order_items", ["order_id"], name: "index_order_items_on_order_id", using: :btree
    add_index "store_order_items", ["product_id"], name: "index_order_items_on_product_id", using: :btree

    create_table "store_orders", force: true do |t|
      t.string   "external_order_id"
      t.string   "sales_channel"
      t.integer  "user_id"
      t.string   "cart_key"
      t.integer  "affiliate_campaign_id"
      t.integer  "referred_by"
      t.integer  "coupon_id"
      t.integer  "voucher_id"
      t.boolean  "combined",                                       default: false, null: false
      t.boolean  "gift",                                           default: false, null: false
      t.decimal  "tax_amount",            precision: 10, scale: 2, default: 0.0,   null: false
      t.decimal  "tax_rate",              precision: 5,  scale: 2, default: 0.0,   null: false
      t.decimal  "shipping_cost",         precision: 6,  scale: 2, default: 0.0,   null: false
      t.string   "shipping_method"
      t.decimal  "discount_amount",       precision: 10, scale: 2, default: 0.0,   null: false
      t.decimal  "credit_applied",        precision: 10, scale: 2, default: 0.0,   null: false
      t.decimal  "subtotal",              precision: 10, scale: 2, default: 0.0,   null: false
      t.decimal  "total",                 precision: 10, scale: 2, default: 0.0,   null: false
      t.string   "status",                                                         null: false
      t.datetime "submitted"
      t.string   "shipping_name"
      t.string   "shipping_company"
      t.string   "shipping_street1"
      t.string   "shipping_street2"
      t.string   "shipping_city"
      t.string   "shipping_state"
      t.string   "shipping_zip"
      t.string   "shipping_country"
      t.string   "billing_name"
      t.string   "billing_company"
      t.string   "billing_street1"
      t.string   "billing_street2"
      t.string   "billing_city"
      t.string   "billing_state"
      t.string   "billing_zip"
      t.string   "billing_country"
      t.text     "customer_note"
      t.string   "notify_email"
      t.string   "contact_phone"
      t.string   "payment_method",                                 default: "",    null: false
      t.string   "cc_type"
      t.string   "cc_number"
      t.string   "cc_code"
      t.integer  "cc_expiration_month"
      t.integer  "cc_expiration_year"
      t.string   "paypal_token"
      t.string   "paypal_payer_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_orders", ["coupon_id"], name: "index_orders_on_coupon_id", using: :btree
    add_index "store_orders", ["user_id"], name: "index_orders_on_user_id", using: :btree
    add_index "store_orders", ["voucher_id"], name: "index_orders_on_voucher_id", using: :btree
    
    create_table "store_product_attributes", force: true do |t|
      t.integer  "product_id",   null: false
      t.integer  "attribute_id", null: false
      t.text     "value",        null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_product_attributes", ["attribute_id"], name: "index_product_attributes_on_attribute_id", using: :btree
    add_index "store_product_attributes", ["product_id"], name: "index_product_attributes_on_product_id", using: :btree

    create_table "store_product_categories", force: true do |t|
      t.integer "product_id",  null: false
      t.integer "category_id", null: false
    end

    add_index "store_product_categories", ["category_id"], name: "index_product_categories_on_category_id", using: :btree
    add_index "store_product_categories", ["product_id"], name: "index_product_categories_on_product_id", using: :btree

    create_table "store_products", force: true do |t|
      t.string   "name",                                                            null: false
      t.string   "group"
      t.string   "product_type"
      t.string   "slug"
      t.integer  "brand_id"
      t.string   "sku",                                             default: "",    null: false
      t.string   "title",                                                           null: false
      t.string   "option_title"
      t.integer  "option_sort"
      t.decimal  "dealer_price",           precision: 10, scale: 2
      t.decimal  "retail_map",             precision: 10, scale: 2
      t.decimal  "price",                  precision: 10, scale: 2,                 null: false
      t.decimal  "msrp",                   precision: 10, scale: 2
      t.decimal  "special_price",          precision: 10, scale: 2
      t.boolean  "free_shipping",                                   default: false, null: false
      t.boolean  "tax_exempt",                                      default: false, null: false
      t.boolean  "hidden",                                          default: false, null: false
      t.boolean  "featured",                                        default: false, null: false
      t.boolean  "require_image_upload",                            default: false, null: false
      t.text     "short_description"
      t.text     "long_description"
      t.string   "keywords"
      t.string   "warranty"
      t.integer  "primary_supplier_id"
      t.integer  "fulfiller_id"
      t.decimal  "item_length",            precision: 10, scale: 3
      t.decimal  "item_width",             precision: 10, scale: 3
      t.decimal  "item_height",            precision: 10, scale: 3
      t.decimal  "item_weight",            precision: 10, scale: 3
      t.decimal  "case_length",            precision: 10, scale: 3
      t.decimal  "case_width",             precision: 10, scale: 3
      t.decimal  "case_height",            precision: 10, scale: 3
      t.decimal  "case_weight",            precision: 10, scale: 3
      t.integer  "case_quantity"
      t.string   "country_of_origin"
      t.integer  "minimum_order_quantity"
      t.integer  "low_threshold"
      t.integer  "committed",                                       default: 0,     null: false
      t.integer  "shipping_lead_time"
      t.datetime "item_availability"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_products", ["brand_id"], name: "index_products_on_brand_id", using: :btree

    create_table "store_purchase_order_items", force: true do |t|
      t.integer  "purchase_order_id",                                                  null: false
      t.string   "sku",               limit: 32,                          default: "", null: false
      t.integer  "quantity",                                              default: 1,  null: false
      t.string   "description"
      t.string   "supplier_code"
      t.string   "upc"
      t.decimal  "unit_price",                   precision: 10, scale: 2
      t.decimal  "discount",                     precision: 10, scale: 2
      t.integer  "quantity_received",                                     default: 0,  null: false
      t.string   "status"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_purchase_order_items", ["sku"], name: "index_purchase_order_items_on_sku_id", using: :btree

    create_table "store_purchase_orders", force: true do |t|
      t.integer  "supplier_id"
      t.string   "status"
      t.date     "issue_date"
      t.date     "due_date"
      t.string   "ship_method"
      t.string   "payment_terms"
      t.string   "ship_to"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "store_shipment_items", force: true do |t|
      t.integer  "shipment_id",   null: false
      t.integer  "order_item_id", null: false
      t.integer  "quantity",      null: false
      t.string   "special_status"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_shipment_items", ["order_item_id"], name: "index_shipment_items_on_product_id", using: :btree
    add_index "store_shipment_items", ["shipment_id"], name: "index_shipment_items_on_shipment_id", using: :btree

    create_table "store_shipments", force: true do |t|
      t.integer  "order_id",                                                                null: false
      t.integer  "sequence",                                                                null: false
      t.integer  "fulfilled_by_id"
      t.string   "status",                                                                  null: false
      t.string   "ship_from_company",                                          default: "", null: false
      t.string   "ship_from_street1",                                          default: "", null: false
      t.string   "ship_from_street2"
      t.string   "ship_from_city",                                             default: "", null: false
      t.string   "ship_from_state",                                            default: "", null: false
      t.string   "ship_from_zip",                                              default: "", null: false
      t.string   "ship_from_country",                                          default: "", null: false
      t.string   "recipient_name",                                                          null: false
      t.string   "recipient_company"
      t.string   "recipient_street1",                                                       null: false
      t.string   "recipient_street2"
      t.string   "recipient_city",                                                          null: false
      t.string   "recipient_state",                                                         null: false
      t.string   "recipient_zip",                                                           null: false
      t.string   "recipient_country",                                                       null: false
      t.string   "ship_method"
      t.string   "tracking_number"
      t.date     "ship_date"
      t.decimal  "ship_cost",                          precision: 6, scale: 2
      t.integer  "package_length"
      t.integer  "package_width"
      t.integer  "package_height"
      t.decimal  "package_weight",                     precision: 6, scale: 2
      t.text     "notes"
      t.string   "packaging_type"
      t.string   "drop_off_type"
      t.text     "courier_data",      limit: 16777215
      t.datetime "created_at"
      t.datetime "updated_at"
      t.binary   "label_data",        limit: 16777215
      t.string   "label_format"
    end

    add_index "store_shipments", ["order_id"], name: "index_shipments_on_order_id", using: :btree

    create_table "store_shipping_options", force: true do |t|
      t.string   "name",                                             null: false
      t.decimal  "base_cost",               precision: 10, scale: 2, null: false
      t.decimal  "min_order_amount",        precision: 10, scale: 2
      t.decimal  "max_order_amount",        precision: 10, scale: 2
      t.boolean  "active",                                           null: false
      t.string   "add_product_attribute"
      t.boolean  "international_surcharge",                          null: false
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_sublocations", force: true do |t|
      t.integer  "location_id"
      t.string   "name"
      t.string   "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_sublocations", ["location_id"], name: "index_sub_locations_on_location_id", using: :btree

    create_table "store_tax_rates", force: true do |t|
      t.string   "code",                                     null: false
      t.string   "country_code",                             null: false
      t.string   "state_code",                               null: false
      t.string   "city",                                     null: false
      t.string   "county",                                   null: false
      t.decimal  "rate",             precision: 5, scale: 2, null: false
      t.boolean  "shipping_taxable",                         null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "store_upc", force: true do |t|
      t.string   "code"
      t.string   "item"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "store_user_voucher_history", force: true do |t|
      t.integer  "user_id",                             null: false
      t.integer  "voucher_id"
      t.decimal  "amount",     precision: 10, scale: 2, null: false
      t.integer  "order_id"
      t.string   "notes"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_user_voucher_history", ["order_id"], name: "index_user_voucher_histories_on_order_id", using: :btree
    add_index "store_user_voucher_history", ["user_id"], name: "index_user_voucher_histories_on_user_id", using: :btree
    add_index "store_user_voucher_history", ["voucher_id"], name: "index_user_voucher_histories_on_voucher_id", using: :btree
    
    create_table "store_voucher_groups", force: true do |t|
      t.string   "name",                                null: false
      t.decimal  "value",      precision: 10, scale: 2, null: false
      t.datetime "expires",                             null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "store_vouchers", force: true do |t|
      t.integer  "voucher_group_id", null: false
      t.string   "code",             null: false
      t.datetime "claim_time"
      t.integer  "claimed_by"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "store_vouchers", ["voucher_group_id"], name: "index_vouchers_on_voucher_group_id", using: :btree

    create_table "store_zip_codes", force: true do |t|
      t.string  "code",             limit: 16,                          default: "",    null: false
      t.string  "country_code",     limit: 2,                           default: "",    null: false
      t.string  "state_code",       limit: 2,                           default: "",    null: false
      t.string  "city",             limit: 32,                          default: "",    null: false
      t.string  "county",           limit: 32,                          default: "",    null: false
      t.decimal "latitude",                    precision: 10, scale: 7
      t.decimal "longitude",                   precision: 10, scale: 7
      t.decimal "tax_rate",                    precision: 6,  scale: 2,                 null: false
      t.boolean "shipping_taxable",                                     default: false, null: false
    end
    
  end
end
