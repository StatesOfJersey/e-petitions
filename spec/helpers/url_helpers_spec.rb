require 'rails_helper'

RSpec.describe "url helpers", type: :helper do
  let(:headers) { helper.request.env }

  describe "#admin_root_url" do
    context "when on the public website" do
      before do
        headers["HTTP_HOST"]   = "petitions.gov.je"
        headers["HTTPS"]       = "on"
        headers["SERVER_PORT"] = 443
      end

      it "generates a moderation website url" do
        expect(helper.admin_root_url).to eq("https://moderate.petitions.gov.je/admin")
      end
    end
  end

  describe "#home_url" do
    context "when on the moderation website" do
      before do
        headers["HTTP_HOST"]   = "moderate.petitions.gov.je"
        headers["HTTPS"]       = "on"
        headers["SERVER_PORT"] = 443
      end

      it "generates a public website url" do
        expect(helper.home_url).to eq("https://petitions.gov.je/")
      end
    end
  end
end
