class Parish < ActiveRecord::Base
  has_many :signatures
  has_many :petitions, through: :signatures

  validates :name, presence: true, length: { maximum: 100 }

  before_validation if: :name_changed? do
    self.slug = name.parameterize
  end

  class << self
    def find_by_postcode(postcode)
      parish_name = ParishApi.lookup(postcode)

      begin
        find_or_create_by!(name: parish_name) if parish_name
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end
  end

  def to_param
    slug
  end
end
