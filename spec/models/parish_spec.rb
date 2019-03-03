require 'rails_helper'

RSpec.describe Parish, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:parish)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:slug).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:example_postcode).of_type(:string).with_options(null: true, limit: 10) }
  end

  describe "associations" do
    it { is_expected.to have_many(:signatures) }
    it { is_expected.to have_many(:petitions).through(:signatures) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:slug]).unique }
  end

  describe "validations" do
    subject { FactoryBot.build(:parish) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
  end

  describe "callbacks" do
    describe "slug" do
      context "when creating a parish" do
        let(:parish) { FactoryBot.create(:parish, name: "St. Saviour") }

        it "is generated from the name" do
          expect(parish.slug).to eq("st-saviour")
        end
      end

      context "when updated a parish" do
        let(:parish) { FactoryBot.create(:parish, name: "St. Savior") }

        before do
          parish.update!(name: "St. Saviour")
        end

        it "is regenerated from the name" do
          expect(parish.slug).to eq("st-saviour")
        end
      end
    end
  end

  describe ".find_by_postcode" do
    context "when the parish doesn't exist in the database" do
      it "saves the parish to the database" do
        expect {
          Parish.find_by_postcode("JE11AA")
        }.to change {
          Parish.count
        }.by(1)
      end
    end

    context "when the parish already exists in the database" do
      before do
        FactoryBot.create(:parish, name: "St. Saviour")
      end

      it "returns the existing record" do
        expect {
          Parish.find_by_postcode("JE11AA")
        }.not_to change {
          Parish.count
        }
      end
    end

    context "when the API returns no results" do
      let(:parish) { Parish.find_by_postcode("JE19ZZ") }

      it "returns nil" do
        expect(parish).to be_nil
      end
    end
  end
end
