require 'rails_helper'

RSpec.describe Parish, type: :model do
  include ParishApiHelper

  it "has a valid factory" do
    expect(FactoryBot.build(:parish)).to be_valid
  end

  describe "schema" do
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:slug).of_type(:string).with_options(null: false, limit: 100) }
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
        let!(:parish) { FactoryBot.create(:parish, name: "Coventry North East") }

        it "is generated from the name" do
          expect(parish.slug).to eq("coventry-north-east")
        end
      end

      context "when updated a parish" do
        let!(:parish) { FactoryBot.create(:parish, name: "Coventry North East") }

        before do
          parish.update!(name: "Coventry North")
        end

        it "is regenerated from the name" do
          expect(parish.slug).to eq("coventry-north")
        end
      end
    end
  end

  describe ".find_by_postcode" do
    before do
      stub_parish_api_wsdl
    end

    context "when the parish doesn't exist in the database" do
      before do
        stub_parish_api_response("JE11AA", File.read("spec/fixtures/parish_api/st_saviour.xml"))
      end

      it "saves the parish to the database" do
        parish = Parish.find_by_postcode("JE11AA")
        expect(parish.persisted?).to be_truthy
      end
    end

    context "when the parish already exists in the database" do
      before do
        stub_parish_api_response("JE11AA", File.read("spec/fixtures/parish_api/st_saviour.xml"))
      end

      let!(:existing_parish) do
        FactoryBot.create(:parish, {
          name: "St. Saviour"
        })
      end

      it "returns the existing record" do
        parish = Parish.find_by_postcode("JE11AA")
        expect(parish).to eq(existing_parish)
      end
    end

    context "when the API returns no results" do
      before do
        stub_parish_api_response("JE19ZZ", File.read("spec/fixtures/parish_api/no_results.xml"))
      end

      it "returns nil" do
        parish = Parish.find_by_postcode("JE19ZZ")
        expect(parish).to be_nil
      end
    end
  end
end
