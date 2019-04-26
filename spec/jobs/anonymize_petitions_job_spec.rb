require 'rails_helper'

RSpec.describe AnonymizePetitionsJob, type: :job do
  let(:scheduled_time) { Date.tomorrow.beginning_of_day.iso8601 }

  context "for a petition closed in the winter" do
    let!(:petition) {
      FactoryBot.create(:closed_petition, closed_at: "2017-12-29T10:00:00Z")
    }

    around do |example|
      travel_to(now)
      example.run
      travel_back
    end

    context "and the anonymizing date has not passed" do
      let(:now) { "2018-06-28T07:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.not_to change{ petition.reload.anonymized? }
      end
    end

    context "and the anonymizing date has passed" do
      let(:now) { "2018-06-29T07:00:00Z".in_time_zone }

      it "does change the petition debate state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.to change{ petition.reload.anonymized? }.from(false).to(true)
      end
    end
  end

  context "for a petition opened in the summer" do
    let!(:petition) {
      FactoryBot.create(:closed_petition, closed_at: "2018-06-29T10:00:00Z")
    }

    around do |example|
      travel_to(now)
      example.run
      travel_back
    end

    context "and the anonymizing date has not passed" do
      let(:now) { "2018-12-28T07:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.not_to change{ petition.reload.anonymized? }
      end
    end

    context "and the anonymizing date has passed" do
      let(:now) { "2018-12-29T07:00:00Z".in_time_zone }

      it "does change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.to change{ petition.reload.anonymized? }.from(false).to(true)
      end
    end
  end
end
