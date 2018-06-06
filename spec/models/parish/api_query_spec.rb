require 'rails_helper'

RSpec.describe Parish::ApiQuery do
  include ParishApiHelper

  describe "#fetch" do
    before do
      stub_parish_api_wsdl
    end

    context "when the request is unsuccessful" do
      context "when the API key is invalid" do
       before do
         stub_parish_api_response("JE11AA", File.read("spec/fixtures/parish_api/invalid_key.xml"))
       end

        it "returns nil" do
          expect(subject.fetch("JE11AA")).to eq nil
        end

        it "notifies the monitoring service" do
          expect(Appsignal).to receive(:send_exception)

          subject.fetch("JE11AA")
        end
      end

      context "when the response is not HTTP success" do
        before do
          stub_parish_api_response("JE11AA", "", 400)
        end

        it "returns nil" do
          subject.fetch("JE11AA")
        end

        it "notifies the monitoring service" do
          expect(Appsignal).to receive(:send_exception)

          subject.fetch("JE11AA")
        end
      end

      context "when the response does not contain XML" do
        before do
          stub_parish_api_response("JE11AA", "")
        end

        it "returns nil" do
          subject.fetch("JE11AA")
        end

        it "notifies the monitoring service" do
          expect(Appsignal).to receive(:send_exception)

          subject.fetch("JE11AA")
        end
      end
    end

    context "when the request is successful" do
      context "when the postcode is invalid" do
        before do
          stub_parish_api_response("JE19ZZ", File.read("spec/fixtures/parish_api/no_results.xml"))
        end

        it "returns nil" do
          expect(subject.fetch("JE19ZZ")).to eq nil
        end
      end

      context "when the postcode matches a parish" do
        before do
          stub_parish_api_response("JE11AA", File.read("spec/fixtures/parish_api/st_saviour.xml"))
        end

        it "returns the parish name" do
          expect(subject.fetch("JE11AA")).to eq 'St. Saviour'
        end
      end
    end
  end
end
