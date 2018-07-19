require 'rails_helper'

RSpec.describe ParishApi do
  subject { described_class }

  describe "#lookup" do
    context "when the request is unsuccessful" do
      context "when host is unreachable" do
        before do
          stub_parish_api_for("JE11AA").to_raise(Errno::EHOSTUNREACH)
        end

        it "returns nil" do
          expect(subject.lookup("JE11AA")).to eq nil
        end

        it "notifies the monitoring service" do
          expect(Appsignal).to receive(:send_exception)

          subject.lookup("JE11AA")
        end
      end

      context "when the API key is invalid" do
        before do
          stub_parish_api_for("JE11AA").to_return(parish_api_response(:ok, "invalid_key"))
        end

        it "returns nil" do
          expect(subject.lookup("JE11AA")).to eq nil
        end

        it "notifies the monitoring service" do
          expect(Appsignal).to receive(:send_exception)

          subject.lookup("JE11AA")
        end
      end

      context "when the response is not HTTP success" do
        before do
          stub_parish_api_for("JE11AA").to_return(parish_api_response(:bad_request){ "400 Bad Request"})
        end

        it "returns nil" do
          subject.lookup("JE11AA")
        end

        it "notifies the monitoring service" do
          expect(Appsignal).to receive(:send_exception)

          subject.lookup("JE11AA")
        end
      end

      context "when the response does not contain XML" do
        before do
          stub_parish_api_for("JE11AA").to_return(parish_api_response(:ok){ "{}" })
        end

        it "returns nil" do
          subject.lookup("JE11AA")
        end

        it "notifies the monitoring service" do
          expect(Appsignal).to receive(:send_exception)

          subject.lookup("JE11AA")
        end
      end
    end

    context "when the request is successful" do
      context "when the postcode is invalid" do
        before do
          stub_parish_api_for("JE19ZZ").to_return(parish_api_response(:ok, "no_results"))
        end

        it "returns nil" do
          expect(subject.lookup("JE19ZZ")).to eq nil
        end
      end

      context "when the postcode matches a parish" do
        before do
          stub_parish_api_for("JE11AA").to_return(parish_api_response(:ok, "st_saviour"))
        end

        it "returns the parish name" do
          expect(subject.lookup("JE11AA")).to eq "St. Saviour"
        end
      end

      context "when the postcode is not sanitized" do
        before do
          stub_parish_api_for("JE11AA").to_return(parish_api_response(:ok, "st_saviour"))
        end

        it "returns the parish name" do
          expect(subject.lookup("JE1 1AA")).to eq "St. Saviour"
        end
      end
    end
  end
end
