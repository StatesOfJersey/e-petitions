require 'rails_helper'

RSpec.describe Admin::StatisticsController, type: :controller, admin: true do
  context "when not logged in" do
    [
      ["GET", "/admin/stats", :index, nil, {}],
      ["GET", "/admin/stats/moderation/week.csv", :moderation, "csv", { period: "week" }],
      ["GET", "/admin/stats/moderation/month.csv", :moderation, "csv", { period: "month" }]
    ].each do |method, path, action, format, params|

      describe "#{method} #{path}" do
        before { process action, method: method, format: format, params: params }

        it "redirects to the login page" do
          expect(response).to redirect_to("https://moderate.petitions.gov.je/admin/login")
        end
      end

    end
  end

  context "when logged in as a moderator requiring a password reset" do
    let(:moderator) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(moderator) }

    [
      ["GET", "/admin/stats", :index, nil, {}],
      ["GET", "/admin/stats/moderation/week.csv", :moderation, "csv", { period: "week" }],
      ["GET", "/admin/stats/moderation/month.csv", :moderation, "csv", { period: "month" }]
    ].each do |method, path, action, format, params|

      describe "#{method} #{path}" do
        before { process action, method: method, params: params }

        it "redirects to the admin profile page" do
          expect(response).to redirect_to("https://moderate.petitions.gov.je/admin/profile/#{moderator.id}/edit")
        end
      end

    end
  end

  context "when logged in as a moderator" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /admin/stats" do
      before { get :index }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :index template" do
        expect(response).to render_template("admin/statistics/index")
      end
    end

    describe "GET /admin/stats/week.csv" do
      before do
        expect(Statistics).to receive(:moderation).with(by: "week")

        get :moderation, format: "csv", params: { period: "week" }
      end

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :moderation template" do
        expect(response).to render_template("admin/statistics/moderation")
      end

      it "returns a CSV file" do
        expect(response.content_type).to eq("text/csv; charset=utf-8")
      end

      it "sets the content disposition" do
        expect(response['Content-Disposition']).to match(/attachment; filename=moderation-by-week\.csv/)
      end
    end

    describe "GET /admin/stats/month.csv" do
      before do
        expect(Statistics).to receive(:moderation).with(by: "month")

        get :moderation, format: "csv", params: { period: "month" }
      end

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :moderation template" do
        expect(response).to render_template("admin/statistics/moderation")
      end

      it "returns a CSV file" do
        expect(response.content_type).to eq("text/csv; charset=utf-8")
      end

      it "sets the content disposition" do
        expect(response['Content-Disposition']).to match(/attachment; filename=moderation-by-month\.csv/)
      end
    end
  end
end
