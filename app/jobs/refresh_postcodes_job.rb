class RefreshPostcodesJob < ApplicationJob
  queue_as :low_priority

  def perform
    Postcode.find_each do |postcode|
      RefreshPostcodeJob.perform_later(postcode.id)
    end
  end
end
