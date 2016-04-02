Setting.create(domain_id: 1, section: 'store', key: 'Order Copy Recipient', value: 'admin@example.com', value_type: 'string')
Setting.create(domain_id: 1, section: 'store', key: 'Checkout Require Login', value: 'true', value_type: 'boolean')
Setting.create(domain_id: 1, section: 'store', key: 'Enable PayPal', value: 'true', value_type: 'boolean')

SearchPath.create(short_code: 'o', url: '/admin/store/orders', description: 'Search for an order by order ID')
SearchPath.create(short_code: 'p', url: '/admin/store/products', description: 'Search for a product by title or SKU')
SearchPath.create(short_code: 'po', url: '/admin/inventory/purchase_orders', description: 'Search for a purchase order by PO number')
SearchPath.create(short_code: 'upc', url: '/admin/store/upc', description: 'Search for a UPC code')

Permission.create(section: 'store', resource: 'admin', action: 'login')

Permission.create(section: 'store', resource: 'brand', action: 'create')
Permission.create(section: 'store', resource: 'brand', action: 'update')
Permission.create(section: 'store', resource: 'brand', action: 'destroy')
Permission.create(section: 'store', resource: 'brand', action: 'reset_password')

Permission.create(section: 'store', resource: 'product', action: 'read')
Permission.create(section: 'store', resource: 'product', action: 'create')
Permission.create(section: 'store', resource: 'product', action: 'update')
Permission.create(section: 'store', resource: 'product', action: 'destroy')

Permission.create(section: 'store', resource: 'order', action: 'read')
Permission.create(section: 'store', resource: 'order', action: 'create')
Permission.create(section: 'store', resource: 'order', action: 'update')
Permission.create(section: 'store', resource: 'order', action: 'destroy')
Permission.create(section: 'store', resource: 'order', action: 'ship')

Permission.create(section: 'store', resource: 'coupon', action: 'read')
Permission.create(section: 'store', resource: 'coupon', action: 'create')
Permission.create(section: 'store', resource: 'coupon', action: 'update')
Permission.create(section: 'store', resource: 'coupon', action: 'destroy')

Permission.create(section: 'store', resource: 'voucher', action: 'read')
Permission.create(section: 'store', resource: 'voucher', action: 'create')
Permission.create(section: 'store', resource: 'voucher', action: 'update')
Permission.create(section: 'store', resource: 'voucher', action: 'destroy')

Permission.create(section: 'store', resource: 'daily_deal', action: 'read')
Permission.create(section: 'store', resource: 'daily_deal', action: 'create')
Permission.create(section: 'store', resource: 'daily_deal', action: 'update')
Permission.create(section: 'store', resource: 'daily_deal', action: 'destroy')

Permission.create(section: 'store', resource: 'invoice_image', action: 'read')
Permission.create(section: 'store', resource: 'invoice_image', action: 'create')
Permission.create(section: 'store', resource: 'invoice_image', action: 'update')
Permission.create(section: 'store', resource: 'invoice_image', action: 'destroy')

Permission.create(section: 'store', resource: 'upc_code', action: 'read')
Permission.create(section: 'store', resource: 'upc_code', action: 'create')
Permission.create(section: 'store', resource: 'upc_code', action: 'update')
Permission.create(section: 'store', resource: 'upc_code', action: 'destroy')

Permission.create(section: 'store', resource: 'purchase_order', action: 'read')
Permission.create(section: 'store', resource: 'purchase_order', action: 'create')
Permission.create(section: 'store', resource: 'purchase_order', action: 'update')
Permission.create(section: 'store', resource: 'purchase_order', action: 'destroy')
Permission.create(section: 'store', resource: 'purchase_order', action: 'receive')