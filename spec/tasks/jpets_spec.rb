require 'rails_helper'

RSpec.describe "jpets:enqueue_petitions_report_if_configured_for_today", type: :task do
  let(:wednesday_date) { Date.parse('2018-06-20') }

  context "when the configured report day is today" do
    before do
      allow(Site).to receive(:petition_report_day_of_week).and_return(Date::DAYS_INTO_WEEK[:wednesday])
      allow(Site).to receive(:petition_report_hour_of_day).and_return(23)
    end

    it "enqueues the email report job for the configured hour" do
      travel_to(wednesday_date) do
        expect { subject.invoke }.to have_enqueued_job(EmailPetitionsReportJob).at(Time.current.change(hour: 23))
      end
    end
  end

  context "when the the configured report day is not today" do
    before do
      allow(Site).to receive(:petition_report_day_of_week).and_return(Date::DAYS_INTO_WEEK[:monday])
      allow(Site).to receive(:petition_report_hour_of_day).and_return(23)
    end

    it "does not enqueue a report job" do
      travel_to(wednesday_date) do
        expect { subject.invoke }.to_not have_enqueued_job(EmailPetitionsReportJob)
      end
    end
  end
end
