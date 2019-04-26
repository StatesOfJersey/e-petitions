class Parish < ActiveRecord::Base
  EXAMPLE_POSTCODES = {
    "Grouville"    => "JE39GA",
    "St. Brelade"  => "JE38BS",
    "St. Clement"  => "JE26FP",
    "St. Helier"   => "JE23NN",
    "St. John"     => "JE34EJ",
    "St. Lawrence" => "JE31NG",
    "St. Martin"   => "JE36HW",
    "St. Mary"     => "JE33AS",
    "St. Ouen"     => "JE32HY",
    "St. Peter"    => "JE37AH",
    "St. Saviour"  => "JE27LF",
    "Trinity"      => "JE35JB"
  }

  has_many :signatures
  has_many :petitions, through: :signatures

  validates :name, presence: true, length: { maximum: 100 }

  before_validation if: :name_changed? do
    self.slug = name.parameterize
    self.example_postcode ||= EXAMPLE_POSTCODES[name]
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
