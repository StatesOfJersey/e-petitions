require 'rails_helper'

RSpec.describe AdminMailer, '#petitions_report', type: :mailer do
  let(:now) { Time.current }

  let!(:recent_open_petition_1) { FactoryBot.create :open_petition, action: 'Plant more trees', signature_count: 1, last_signed_at: now.beginning_of_day - 1.minute }
  let!(:recent_open_petition_2) { FactoryBot.create :open_petition, action: 'Plant more flowers', signature_count: 2, last_signed_at: now.beginning_of_day - 1.week + 1.minute }
  let!(:recent_open_petition_3) { FactoryBot.create :open_petition, open_at: now.beginning_of_day - 1.week + 1.minute, action: 'Plant more hedges', last_signed_at: nil }

  let!(:recent_rejected_petition) { FactoryBot.create :rejected_petition, action: 'Plant more cabbages' }
  let!(:older_open_petition_signed) { FactoryBot.create :open_petition, action: 'Plant more mushrooms', open_at: (now.beginning_of_day - 1.week) - 1.minute, last_signed_at: (now.beginning_of_day - 1.week) - 1.minute }
  let!(:older_open_petition_unsigned) { FactoryBot.create :open_petition, action: 'Plant more wheat', open_at: (now.beginning_of_day - 1.week) - 1.minute, last_signed_at: nil }

  let(:mail) { AdminMailer.petitions_report }

  it 'mails to the address set on the Site' do
    expect(Site).to receive(:petition_report_email).and_return("gimmemyreport@example.com")
    expect(mail.to).to eq ['gimmemyreport@example.com']
  end

  it 'has a subject with relevant dates' do
    travel_to "2019-01-03" do
      expect(mail.subject).to eq 'Petitions report 27 Dec 2018 - 03 Jan 2019'
    end
  end

  it 'lists petitions opened or signed in the last week' do
    expect(mail).to have_body_text("3 petitions were opened or signed in the last week")
    expect(mail).to have_body_text("Plant more trees")
    expect(mail).to have_body_text("Plant more flowers")
    expect(mail).to have_body_text("Plant more hedges")
  end

  it 'does not list irrelevant petitions or those last active over a week ago' do
    expect(mail).not_to have_body_text("Plant more mushrooms")
    expect(mail).not_to have_body_text("Plant more cabbages")
    expect(mail).not_to have_body_text("Plant more wheat")
  end
end
