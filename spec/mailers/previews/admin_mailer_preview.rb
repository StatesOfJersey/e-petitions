class AdminMailerPreview < ActionMailer::Preview
  def petitions_report
    AdminMailer.petitions_report
  end
end
