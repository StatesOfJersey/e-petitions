class RefreshPostcodeJob < ApplicationJob
  queue_as :low_priority

  def perform(postcode)
    ParishApi.lookup(postcode, force: true)
  end
end
