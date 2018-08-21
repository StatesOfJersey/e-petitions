class Admin::TakeDownController < Admin::AdminController
  before_action :fetch_petition

  def show
    render 'admin/petitions/show'
  end

  def update
    if @petition.reject(rejection_params[:rejection])
      if send_email_to_creator_and_sponsors?
        send_notifications
        message = :petition_taken_down_with_notifications
      else
        message = :petition_taken_down
      end

      redirect_to [:admin, @petition], notice: message
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def rejection_params
    params.require(:petition).permit(rejection: [:code, :details])
  end

  def send_email_to_creator_and_sponsors?
    params.key?(:save_and_email)
  end

  def send_notifications
    NotifyEveryoneOfModerationDecisionJob.perform_later(@petition)
  end
end
