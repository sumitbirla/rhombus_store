module PurchaseOrderHelper
  
  def po_status(po, css = '')
    css_class = css + ' '
    
    if po.status == 'new'
      css_class += 'label-info'
    elsif ['late', 'cancelled'].include?(po.status)
      css_class += 'label-danger'
    elsif po.status == 'received'
      css_class += 'label-success'
    elsif po.status == 'released'
      css_class += 'label-success'
    elsif po.status == 'closed'
      css_class += 'label-primary'
    else
      css_class += 'label-primary'
    end
    
    "<span class='label #{css_class}'>#{po.status}</span>".html_safe
  end
  
  def poi_status(poi, css = '')
    css_class = css + ' '
    
    if poi.status == 'received'
      css_class += 'label-success'
    elsif poi.status == 'closed'
      css_class += 'label-info'
    elsif poi.status == 'canceled'
      css_class += 'label-danger'
    else
      css_class += 'label-warning'
    end
    
    "<span class='label #{css_class}'>#{poi.status}</span>".html_safe
  end
  
  
end