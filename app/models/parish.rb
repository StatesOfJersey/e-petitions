require_dependency 'parish/api_query'

class Parish < ActiveRecord::Base
  has_many :signatures
  has_many :petitions, through: :signatures

  validates :name, presence: true, length: { maximum: 100 }

  before_validation if: :name_changed? do
    self.slug = name.parameterize
  end

  class << self
    def find_by_postcode(postcode)
      parish_name = ApiQuery.new.fetch(postcode)

      find_or_create_by!(name: parish_name) if parish_name
    end
  end

  def to_param
    slug
  end
end
