module PurchaseOrderHelper
  
  def po_status(po, css = '')
    css_class = css + ' '
    
    if po.status == 'open'
      css_class += 'label-info'
    elsif ['late', 'cancelled'].include?(po.status)
      css_class += 'label-warning'
    elsif po.status == 'received'
      css_class += 'label-success'
    elsif po.status == 'partially_received'
      css_class += 'label-important'
    else
      css_class += 'label-default'
    end
    
    "<span class='label #{css_class}'>#{po.status}</span>".html_safe
  end
  
  def poi_status(poi, css = '')
    css_class = css + ' '
    
    if poi.status == 'partial'
      css_class += 'label-important'
    elsif poi.status == 'received'
      css_class += 'label-success'
    else
      css_class += 'label-warning'
    end
    
    "<span class='label #{css_class}'>#{poi.status}</span>".html_safe
  end
  
  
end