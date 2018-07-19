require 'rails_helper'

RSpec.describe Postcode, type: :model do
  describe "schema" do
    it { is_expected.to have_db_column(:postcode).of_type(:string).with_options(limit: 10, primary: true) }
    it { is_expected.to have_db_column(:parish).of_type(:string).with_options(limit: 30, null: false) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:expires_at).of_type(:datetime).with_options(null: true) }
  end
end
