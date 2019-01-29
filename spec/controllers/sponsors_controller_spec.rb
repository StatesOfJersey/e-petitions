require 'rails_helper'

RSpec.describe SponsorsController, type: :controller do
  let(:rate_limit) { double(:rate_limit) }
  let(:ip_blocked) { false }

  before do
    parish = FactoryBot.create(:parish, :st_saviour, id: 1)
    allow(Parish).to receive(:find_by_postcode).with("JE11AA").and_return(parish)
    allow(RateLimit).to receive(:first_or_create!).and_return(rate_limit)
    allow(rate_limit).to receive(:permitted?).and_return(!ip_blocked)
    allow(rate_limit).to receive(:exceeded?).and_return(false)
  end

  describe "GET /petitions/:petition_id/sponsors/new" do
    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :new, params: { petition_id: 1, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :new, params: { petition_id: petition.id, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the creator's signature has not been validated" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:creator) { petition.creator }

      it "validates the creator's signature" do
        expect {
          get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
        }.to change {
          creator.reload.validated?
        }.from(false).to(true)
      end
    end

    %w[flagged hidden].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          get :new, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        context "and the ip address is not blocked" do
          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "assigns the @signature instance variable with a new signature" do
            expect(assigns[:signature]).not_to be_persisted
          end

          it "renders the sponsors/new template" do
            expect(response).to render_template("sponsors/new")
          end

          context "and has one remaining sponsor slot" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

            it "doesn't redirect to the petition moderation info page" do
              expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
            end
          end

          context "and has reached the maximum number of sponsors" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

            it "redirects to the petition moderation info page" do
              expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
            end
          end
        end

        context "and the ip address is blocked" do
          let(:ip_blocked) { true }

          it "responds with a '403 Forbidden' response" do
            expect(response).to have_http_status(:forbidden)
          end

          it "renders the 'petitions/blocked' template" do
            expect(response).to render_template("signatures/blocked")
          end
        end
      end
    end
  end

  describe "POST /petitions/:petition_id/sponsors/new" do
    let(:params) do
      {
        name: "Ted Berry",
        email: "ted@example.com",
        jersey_resident: "1",
        postcode: "JE1 1AA"
      }
    end

    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :confirm, params: { petition_id: 1, token: 'token', signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :confirm, params: { petition_id: petition.id, token: 'token', signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[flagged hidden].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            post :confirm, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          post :confirm, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          post :confirm, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
        end

        context "and the ip address is not blocked" do
          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "assigns the @signature instance variable with a new signature" do
            expect(assigns[:signature]).not_to be_persisted
          end

          it "sets the signature's params" do
            expect(assigns[:signature].name).to eq("Ted Berry")
            expect(assigns[:signature].email).to eq("ted@example.com")
            expect(assigns[:signature].jersey_resident).to eq("1")
            expect(assigns[:signature].postcode).to eq("JE11AA")
          end

          it "records the IP address on the signature" do
            expect(assigns[:signature].ip_address).to eq("0.0.0.0")
          end

          it "renders the sponsors/confirm template" do
            expect(response).to render_template("sponsors/confirm")
          end

          context "and the params are invalid" do
            let(:params) do
              {
                name: "Ted Berry",
                email: "",
                jersey_resident: "1",
                postcode: "12345"
              }
            end

            it "renders the sponsors/new template" do
              expect(response).to render_template("sponsors/new")
            end
          end

          context "and has one remaining sponsor slot" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

            it "doesn't redirect to the petition moderation info page" do
              expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
            end
          end

          context "and has reached the maximum number of sponsors" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

            it "redirects to the petition moderation info page" do
              expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
            end
          end
        end

        context "and the ip address is blocked" do
          let(:ip_blocked) { true }

          it "responds with a '403 Forbidden' response" do
            expect(response).to have_http_status(:forbidden)
          end

          it "renders the 'petitions/blocked' template" do
            expect(response).to render_template("signatures/blocked")
          end
        end
      end
    end
  end

  describe "POST /petitions/:petition_id/sponsors" do
    let(:params) do
      {
        name: "Ted Berry",
        email: "ted@example.com",
        jersey_resident: "1",
        postcode: "JE1 1AA"
      }
    end

    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :create, params: { petition_id: 1, token: 'token', signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          post :create, params: { petition_id: petition.id, token: 'token', signature: params }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[flagged hidden].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        context "and the signature is not a duplicate" do
          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          context "and the ip address is not blocked" do
            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "assigns the @signature instance variable with a saved signature" do
              expect(assigns[:signature]).to be_persisted
            end

            it "sets the signature's params" do
              expect(assigns[:signature].name).to eq("Ted Berry")
              expect(assigns[:signature].email).to eq("ted@example.com")
              expect(assigns[:signature].jersey_resident).to eq("1")
              expect(assigns[:signature].postcode).to eq("JE11AA")
            end

            it "records the IP address on the signature" do
              expect(assigns[:signature].ip_address).to eq("0.0.0.0")
            end

            it "sends a confirmation email" do
              expect(last_email_sent).to deliver_to("ted@example.com")
              expect(last_email_sent).to have_subject("Please confirm your email address")
            end

            it "redirects to the thank you page" do
              expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
            end

            context "and the params are invalid" do
              let(:params) do
                {
                  name: "Ted Berry",
                  email: "",
                  jersey_resident: "1",
                  postcode: "JE1 1AA"
                }
              end

              it "renders the sponsors/new template" do
                expect(response).to render_template("sponsors/new")
              end
            end
          end

          context "and the ip address is blocked" do
            let(:ip_blocked) { true }

            it "responds with a '403 Forbidden' response" do
              expect(response).to have_http_status(:forbidden)
            end

            it "renders the 'petitions/blocked' template" do
              expect(response).to render_template("signatures/blocked")
            end
          end
        end

        context "and the signature is a pending duplicate" do
          let!(:signature) { FactoryBot.create(:pending_signature, params.merge(petition: petition)) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "assigns the @signature instance variable to the original signature" do
            expect(assigns[:signature]).to eq(signature)
          end

          it "re-sends the confirmation email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Please confirm your email address")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and the signature is a validated duplicate" do
          let!(:signature) { FactoryBot.create(:validated_signature, params.merge(petition: petition)) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "assigns the @signature instance variable to the original signature" do
            expect(assigns[:signature]).to eq(signature)
          end

          it "sends a duplicate signature email" do
            expect(last_email_sent).to deliver_to("ted@example.com")
            expect(last_email_sent).to have_subject("Duplicate signature of petition")
          end

          it "redirects to the thank you page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/sponsors/thank-you?token=#{petition.sponsor_token}")
          end
        end

        context "and has one remaining sponsor slot" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "doesn't redirect to the petition moderation info page" do
            expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end

        context "and has reached the maximum number of sponsors" do
          let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

          before do
            perform_enqueued_jobs {
              post :create, params: { petition_id: petition.id, token: petition.sponsor_token, signature: params }
            }
          end

          it "redirects to the petition moderation info page" do
            expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
          end
        end
      end
    end
  end

  describe "GET /petitions/:petition_id/signatures/thank-you" do
    context "when the petition doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :thank_you, params: { petition_id: 1, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :thank_you, params: { petition_id: petition.id, token: 'token' }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    %w[flagged hidden].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :thank_you, params: { petition_id: petition.id, token: petition.sponsor_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }

        before do
          get :thank_you, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "doesn't redirect to the petition page" do
          expect(response).not_to redirect_to("/petitions/#{petition.id}")
        end

        it "renders the signatures/thank_you template" do
          expect(response).to render_template("signatures/thank_you")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition) }

        before do
          get :thank_you, params: { petition_id: petition.id, token: petition.sponsor_token }
        end

        context "and the ip address is not blocked" do
          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "renders the signatures/thank_you template" do
            expect(response).to render_template("signatures/thank_you")
          end

          context "and has one remaining sponsor slot" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

            it "doesn't redirect to the petition moderation info page" do
              expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
            end

            it "renders the signatures/thank_you template" do
              expect(response).to render_template("signatures/thank_you")
            end
          end

          context "and has reached the maximum number of sponsors" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

            it "doesn't redirect to the petition moderation info page" do
              expect(response).not_to redirect_to("/petitions/#{petition.id}/moderation-info")
            end

            it "renders the signatures/thank_you template" do
              expect(response).to render_template("signatures/thank_you")
            end
          end
        end

        context "and the ip address is blocked" do
          let(:ip_blocked) { true }

          it "responds with a '403 Forbidden' response" do
            expect(response).to have_http_status(:forbidden)
          end

          it "renders the 'petitions/blocked' template" do
            expect(response).to render_template("signatures/blocked")
          end
        end
      end
    end
  end

  describe "GET /sponsors/:id/verify" do
    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: 1, token: "token" }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: "token" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition, sponsor: true) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition, sponsor: true) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    %w[flagged hidden].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :verify, params: { id: signature.id, token: signature.perishable_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

        before do
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        end

        it "assigns the @signature instance variable" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("/petitions/#{petition.id}")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

        before do
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        end

        context "and the ip address is not blocked" do
          it "assigns the @signature instance variable" do
            expect(assigns[:signature]).to eq(signature)
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "validates the signature" do
            expect(assigns[:signature]).to be_validated
          end

          it "records the parish id on the signature" do
            expect(assigns[:signature].parish_id).to eq("1")
          end

          it "redirects to the signed signature page" do
            expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored?token=#{signature.perishable_token}")
          end

          context "and the signature has already been validated" do
            let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

            it "doesn't set the flash :notice message" do
	            expect(flash[:notice]).to be_nil
            end
          end

          context "and has one remaining sponsor slot" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "validates the signature" do
              expect(assigns[:signature]).to be_validated
            end

            it "redirects to the signed signature page" do
              expect(response).to redirect_to("/sponsors/#{signature.id}/sponsored?token=#{signature.perishable_token}")
            end
          end

          context "and has reached the maximum number of sponsors" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors, sponsors_signed: true) }

            it "redirects to the petition moderation info page" do
              expect(response).to redirect_to("/petitions/#{petition.id}/moderation-info")
            end
          end
        end

        context "and the ip address is blocked" do
          let(:ip_blocked) { true }

          it "responds with a '403 Forbidden' response" do
            expect(response).to have_http_status(:forbidden)
          end

          it "renders the 'petitions/blocked' template" do
            expect(response).to render_template("signatures/blocked")
          end
        end
      end
    end
  end

  describe "GET /sponsors/:id/sponsored" do
    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: 1, token: "token" }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature token is invalid" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: signature.id, token: "token" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is fraudulent" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:fraudulent_signature, petition: petition, sponsor: true) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: signature.id, token: signature.perishable_token }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature is invalidated" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:invalidated_signature, petition: petition, sponsor: true) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :signed, params: { id: signature.id, token: signature.perishable_token }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    %w[flagged hidden].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition, sponsor: true) }

        it "raises an ActiveRecord::RecordNotFound exception" do
          expect {
            get :signed, params: { id: signature.id, token: signature.perishable_token }
          }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    %w[open closed rejected].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition, sponsor: true) }

        before do
          get :signed, params: { id: signature.id, token: signature.perishable_token }
        end

        it "assigns the @signature instance variable" do
          expect(assigns[:signature]).to eq(signature)
        end

        it "assigns the @petition instance variable" do
          expect(assigns[:petition]).to eq(petition)
        end

        it "doesn't redirect to the petition page" do
          expect(response).not_to redirect_to("/petitions/#{petition.id}")
        end

        it "renders the sponsors/signed template" do
          expect(response).to render_template("sponsors/signed")
        end
      end
    end

    %w[pending validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:validated_signature, :just_signed, petition: petition, sponsor: true) }

        before do
          get :signed, params: { id: signature.id, token: signature.perishable_token }
        end

        context "and the ip address is not blocked" do
          it "assigns the @signature instance variable" do
            expect(assigns[:signature]).to eq(signature)
          end

          it "assigns the @petition instance variable" do
            expect(assigns[:petition]).to eq(petition)
          end

          it "marks the signature has having seen the confirmation page" do
            expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
          end

          it "renders the sponsors/signed template" do
            expect(response).to render_template("sponsors/signed")
          end

          context "and the signature has not been validated" do
            let(:signature) { FactoryBot.create(:pending_signature, petition: petition, sponsor: true) }

            it "redirects to the verify page" do
              expect(response).to redirect_to("/sponsors/#{signature.id}/verify?token=#{signature.perishable_token}")
            end
          end

          context "and the signature has already seen the confirmation page" do
            let(:signature) { FactoryBot.create(:validated_signature, petition: petition, sponsor: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "renders the sponsors/signed template" do
              expect(response).to render_template("sponsors/signed")
            end
          end

          context "and has one remaining sponsor slot" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 2, sponsors_signed: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "marks the signature has having seen the confirmation page" do
              expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
            end

            it "renders the sponsors/signed template" do
              expect(response).to render_template("sponsors/signed")
            end
          end

          context "and has reached the maximum number of sponsors" do
            let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: Site.maximum_number_of_sponsors - 1, sponsors_signed: true) }

            it "assigns the @signature instance variable" do
              expect(assigns[:signature]).to eq(signature)
            end

            it "assigns the @petition instance variable" do
              expect(assigns[:petition]).to eq(petition)
            end

            it "marks the signature has having seen the confirmation page" do
              expect(assigns[:signature].seen_signed_confirmation_page).to eq(true)
            end

            it "renders the sponsors/signed template" do
              expect(response).to render_template("sponsors/signed")
            end
          end
        end

        context "and the ip address is blocked" do
          let(:ip_blocked) { true }

          it "responds with a '403 Forbidden' response" do
            expect(response).to have_http_status(:forbidden)
          end

          it "renders the 'petitions/blocked' template" do
            expect(response).to render_template("signatures/blocked")
          end
        end
      end
    end
  end
end
