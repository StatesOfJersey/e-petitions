require 'rails_helper'

RSpec.describe LocalPetitionsController, type: :controller do
  let(:parish) { FactoryBot.create(:parish, name: "Holborn", id: 1) }

  describe "GET /petitions/local" do
    context "when the postcode is valid" do
      before do
        expect(Parish).to receive(:find_by_postcode).with("JE11AA").and_return(parish)

        get :index, params: { postcode: "je1 1aa" }
      end

      it "assigns the sanitized postcode" do
        expect(assigns(:postcode)).to eq("JE11AA")
      end

      it "redirects to the parish page for current popular petitions" do
        expect(response).to redirect_to("/petitions/local/holborn")
      end
    end

    context "when the postcode is invalid" do
      before do
        expect(Parish).to receive(:find_by_postcode).with("JE1A1AA").and_return(nil)
        get :index, params: { postcode: "je1a 1aa" }
      end

      it "assigns the sanitized postcode" do
        expect(assigns(:postcode)).to eq("JE1A1AA")
      end

      it "responds successfully" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template("local_petitions/index")
      end

      it "doesn't assign the parish" do
        expect(assigns(:parish)).to be_nil
      end

      it "doesn't assign the petitions" do
        expect(assigns(:petitions)).to be_nil
      end
    end

    context "when the postcode is blank" do
      before do
        expect(Parish).not_to receive(:find_by_postcode)
        get :index, params: { postcode: "" }
      end

      it "responds successfully" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template("local_petitions/index")
      end
    end

    context "when the postcode is not set" do
      before do
        expect(Parish).not_to receive(:find_by_postcode)
        get :index
      end

      it "responds successfully" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template("local_petitions/index")
      end
    end
  end

  describe "GET /petitions/local/:id" do
    let(:petitions) { double(:petitions) }

    before do
      expect(Parish).to receive(:find_by_slug!).with("st_saviour").and_return(parish)
      expect(Petition).to receive(:popular_in_parish).with(1, 50).and_return(petitions)

      get :show, params: { id: "st_saviour" }
    end

    it "renders the show template" do
      expect(response).to render_template("local_petitions/show")
    end

    it "assigns the parish" do
      expect(assigns(:parish)).to eq(parish)
    end

    it "assigns the petitions" do
      expect(assigns(:petitions)).to eq(petitions)
    end
  end

  describe "GET /petitions/local/:id/all" do
    let(:petitions) { double(:petitions) }

    before do
      expect(Parish).to receive(:find_by_slug!).with("st_saviour").and_return(parish)
      expect(Petition).to receive(:all_popular_in_parish).with(1, 50).and_return(petitions)

      get :all, params: { id: "st_saviour" }
    end

    it "renders the all template" do
      expect(response).to render_template("local_petitions/all")
    end

    it "assigns the parish" do
      expect(assigns(:parish)).to eq(parish)
    end

    it "assigns the petitions" do
      expect(assigns(:petitions)).to eq(petitions)
    end
  end
end
