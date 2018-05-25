require 'rails_helper'

RSpec.describe Parish, type: :model do
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

  xdescribe ".find_by_postcode" do
    context "when the parish doesn't exist in the database" do
      it "saves the parish to the database" do
        parish = parish.find_by_postcode("N11TY")
        expect(parish.persisted?).to be_truthy
      end
    end

    context "when the parish already exists in the database" do
      let!(:existing_parish) do
        FactoryBot.create(:parish, {
          name: "Islington South and Finsbury", external_id: "3550", ons_code: "E14000764",
          mp_id: "1536", mp_name: "Emily Thornberry MP", mp_date: "2015-05-07T00:00:00"
        })
      end

      it "returns the existing record" do
        parish = parish.find_by_postcode("N11TY")
        expect(parish).to eq(existing_parish)
      end
    end

    context "when the API returns no results" do
      it "returns nil" do
        parish = parish.find_by_postcode("N11TY")
        expect(parish).to be_nil
      end
    end

    context "when the API returns updated results" do
      let(:parish) do
        parish.find_by_postcode('OL90LS')
      end

      before do
        FactoryBot.create(:parish, {
          name: "Oldham West and Royton", external_id: "3671", ons_code: "E14000871",
          mp_id: "454", mp_name: "Mr Michael Meacher", mp_date: "2015-05-07T00:00:00"
        })
      end

      it "updates the existing parish" do
        expect(parish.mp_name).to eq("Jim McMahon MP")
      end

      it "persists the changes to the database" do
        expect(parish.reload.mp_name).to eq("Jim McMahon MP")
      end
    end
  end
end
