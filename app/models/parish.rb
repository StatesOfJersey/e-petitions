class Parish < ActiveRecord::Base
  has_many :signatures
  has_many :petitions, through: :signatures

  validates :name, presence: true, length: { maximum: 100 }

  before_validation if: :name_changed? do
    self.slug = name.parameterize
  end

  class << self
    def find_by_postcode(postcode)
      # return if Site.disable_constituency_api?
      #
      # results = query.fetch(postcode)
      #
      # if attributes = results.first
      #   parish = find_or_initialize_by(external_id: attributes[:external_id])
      #   parish.attributes = attributes
      #   if parish.changed? || parish.new_record?
      #     parish.save!
      #   end
      #
      #   parish
      # end
    end
  end

  def to_param
    slug
  end
end
