class Postcode < ActiveRecord::Base
  class << self
    def expired(now = Time.current)
      where(arel_table[:expired_at].lt(now))
    end
  end
end
