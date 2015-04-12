module OrderHelper
  
  def order_status(order, css = '')
    css_class = css + ' '

    if order.status == 'shipped'
      css_class += 'label-success'
    elsif ['refunded', 'cancelled'].include?(order.status)
      css_class += 'label-warning'
    elsif order.status == 'completed'
      css_class += 'label-info'
    elsif order.status == 'backordered'
      css_class += 'label-danger'
    else
      css_class += 'label-default'
    end

    "<span class='label #{css_class}'>#{order.status}</span>".html_safe
  end
  
  def product_status(product)
    str = ""
    if product.active
      str += "<span class='label label-success'>active</span> " 
    else
      str += "<span class='label label-warning'>inactive</span> " 
    end
    str += "<i class='fa fa-eye-slash'></i>" if product.hidden
    str.html_safe
  end
  
end