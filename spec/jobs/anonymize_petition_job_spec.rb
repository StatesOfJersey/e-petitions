require 'rails_helper'

RSpec.describe AnonymizePetitionJob, type: :job do
  shared_examples_for "anonymization" do
    let(:timestamp) { "2018-12-31T00:00:00Z".in_time_zone }
    let!(:petition) { FactoryBot.create(:closed_petition, closed_at: "2018-06-30T00:00:00Z") }
    let!(:signature) { FactoryBot.create(signature_type, created_at: created_at, petition: petition) }

    it "anonymizes the signature" do
      expect {
        perform_enqueued_jobs {
          described_class.perform_later(petition, timestamp.iso8601)
        }
      }.to change {
        signature.reload.anonymized_at
      }.from(nil).to(timestamp)
    end

    it "marks the petition as anonymized" do
      expect {
        perform_enqueued_jobs {
          described_class.perform_later(petition, timestamp.iso8601)
        }
      }.to change {
        petition.reload.anonymized_at
      }.from(nil).to(timestamp)
    end
  end

  context "with a pending signature" do
    let(:signature_type) { :pending_signature }

    context "when it was created at the beginning" do
      let(:created_at) { "2018-01-01T12:00:00Z" }

      it_behaves_like "anonymization"
    end

    context "when it was created at the end" do
      let(:created_at) { "2018-06-29T12:00:00Z" }

      it_behaves_like "anonymization"
    end
  end

  context "with a validated signature" do
    let(:signature_type) { :validated_signature }

    context "when it was created at the beginning" do
      let(:created_at) { "2018-01-01T12:00:00Z" }

      it_behaves_like "anonymization"
    end

    context "when it was created at the end" do
      let(:created_at) { "2018-06-29T12:00:00Z" }

      it_behaves_like "anonymization"
    end
  end
end
