class EmailPetitionsReportJob < EmailJob
  self.mailer = AdminMailer
  self.email = :petitions_report
end
