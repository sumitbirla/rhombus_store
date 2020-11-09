module DailyDealHelper

  def deal_status(deal)
    css = "label-default"
    text = "pending"

    if deal.number_sold > deal.max_sales
      css = "label-important"
      text = "sold out"
    elsif deal.start_time < DateTime.now && deal.end_time > DateTime.now && deal.active
      css = "label-success"
      text = "active"
    elsif deal.end_time < DateTime.now
      css = "label-warning"
      text = "expired"
    end

    "<span class='label #{css}'>#{text}</span>".html_safe
  end

end