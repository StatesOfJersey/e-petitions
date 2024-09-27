class AnonymizePetitionJob < ApplicationJob
  queue_as :high_priority

  def perform(petition, time)
    time = time.in_time_zone

    Appsignal.ignore_instrumentation_events do
      petition.signatures.not_anonymized.find_each do |signature|
        begin
          signature.anonymize!(time)
        rescue ActiveRecord::RecordInvalid => exception
          Appsignal.send_exception(exception)
        end
      end

      petition.update!(anonymized_at: time)
    end
  end
end
