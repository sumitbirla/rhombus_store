class DailyDealsController < ApplicationController

  def new_submission
    @deal_submission = DealSubmission.new
    @deal_submission.locations.build
  end
  
  def create_submission
    @deal_submission = DealSubmission.new(deal_submission_params)
    if @deal_submission.save
      DealSubmissionMailer.new_deal_submission(@deal_submission).deliver
      redirect_to action: 'show_submission', id: @deal_submission.id
    else
      render 'new'
    end
  end
  
  def show_submission
    @deal_submission = DealSubmission.find_by(params[:id])
  end

  def show
    @daily_deal = DailyDeal.find_by(slug: params[:slug])
    render 'show'
  end
  
  def email
    @daily_deal = DailyDeal.find(params[:id])
    
    respond_to do |format|
      format.html { render 'email', layout: nil }
      format.text
    end
  end
  
  private
  
    def deal_submission_params
      params.require(:deal_submission).permit!
    end
end
