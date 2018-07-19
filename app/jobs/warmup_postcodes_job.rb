class WarmupPostcodesJob < ApplicationJob
  queue_as :low_priority

  def perform
    ("JE10AA".."JE59ZZ").each do |postcode|
      RefreshPostcodeJob.perform_later(postcode)
    end
  end
end
