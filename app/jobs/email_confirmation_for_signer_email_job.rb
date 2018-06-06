class EmailConfirmationForSignerEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :email_confirmation_for_signer

  rescue_from(ActiveJob::DeserializationError) do |exception|
    Appsignal.send_exception exception
  end

  def perform(signature)
    if rate_limit.exceeded?(signature)
      signature.fraudulent!
    else
      mailer.send(email, signature).deliver_now

      updates, params = [], {}
      updates << "email_count = COALESCE(email_count, 0) + 1"

      if parish = signature.parish
        updates << "parish_id = :parish_id"
        params[:parish_id] = parish.id
      end

      signature.update_all([updates.join(", "), params])
    end
  end

  private

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end
end
