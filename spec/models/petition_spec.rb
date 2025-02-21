require 'rails_helper'
require_relative 'taggable_examples'

RSpec.describe Petition, type: :model do
  context "defaults" do
    it "has pending as default state" do
      p = Petition.new
      expect(p.state).to eq("pending")
    end

    it "generates sponsor token" do
      p = FactoryBot.create(:petition, :sponsor_token => nil)
      expect(p.sponsor_token).not_to be_nil
    end
  end

  describe "associations" do
    it { is_expected.to have_one(:debate_outcome).dependent(:destroy) }
    it { is_expected.to have_one(:government_response).dependent(:destroy) }

    it { is_expected.to have_many(:emails).dependent(:destroy) }
    it { is_expected.to have_many(:invalidations) }
  end

  describe "callbacks" do
    context "when creating a petition" do
      let(:now) { Time.current }

      before do
        Site.update_all(last_petition_created_at: nil)
      end

      it "updates the site's last_petition_created_at column" do
        expect {
          FactoryBot.create(:petition)
        }.to change {
          Site.last_petition_created_at
        }.from(nil).to(be_within(1.second).of(now))
      end
    end
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:action).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:background).with_message(/must be completed/) }
    it { is_expected.to validate_presence_of(:creator).with_message(/must be completed/) }

    it { is_expected.to have_db_column(:action).of_type(:string).with_options(limit: 255, null: false) }
    it { is_expected.to have_db_column(:background).of_type(:string).with_options(limit: 300, null: true) }
    it { is_expected.to have_db_column(:additional_details).of_type(:text).with_options(null: true) }

    it { is_expected.to validate_length_of(:action).is_at_most(80) }
    it { is_expected.to validate_length_of(:background).is_at_most(300) }
    it { is_expected.to validate_length_of(:additional_details).is_at_most(800) }

    it { is_expected.to validate_presence_of(:state).with_message("State '' not recognised") }
    it { is_expected.not_to allow_value("unknown").for(:state) }

    it { is_expected.to allow_value("pending").for(:state) }
    it { is_expected.to allow_value("validated").for(:state) }
    it { is_expected.to allow_value("sponsored").for(:state) }
    it { is_expected.to allow_value("flagged").for(:state) }
    it { is_expected.to allow_value("open").for(:state) }
    it { is_expected.to allow_value("rejected").for(:state) }
    it { is_expected.to allow_value("hidden").for(:state) }

    context "when state is open" do
      subject { FactoryBot.build(:open_petition) }

      it { is_expected.not_to allow_value(nil).for(:open_at) }
      it { is_expected.to allow_value(Time.current).for(:open_at) }
    end
  end

  context "scopes" do
    describe "trending" do
      before(:each) do
        11.times do |count|
          petition = FactoryBot.create(:open_petition, action: "petition ##{count+1}", last_signed_at: Time.current)
          count.times { FactoryBot.create(:validated_signature, petition: petition) }
        end

        @petition_with_old_signatures = FactoryBot.create(:open_petition, action: "petition out of range", last_signed_at: 2.hours.ago)
        @petition_with_old_signatures.signatures.first.update_attribute(:validated_at, 2.hours.ago)
      end

      it "returns petitions trending for the last hour" do
        expect(Petition.trending.map(&:id).include?(@petition_with_old_signatures.id)).to be_falsey
      end

      it "returns the signature count for the last hour as an additional attribute" do
        expect(Petition.trending.first.signature_count_in_period).to eq(11)
        expect(Petition.trending.last.signature_count_in_period).to eq(9)
      end

      it "limits the result to 3 petitions" do
        # 13 petitions signed in the last hour
        2.times do |count|
          petition = FactoryBot.create(:open_petition, action: "petition ##{count+1}", last_signed_at: Time.current)
          count.times { FactoryBot.create(:validated_signature, petition: petition) }
        end

        expect(Petition.trending.to_a.size).to eq(3)
      end

      it "excludes petitions that are not open" do
        petition = FactoryBot.create(:validated_petition)
        20.times{ FactoryBot.create(:validated_signature, petition: petition) }

        expect(Petition.trending.to_a).not_to include(petition)
      end

      it "excludes signatures that have been invalidated" do
        petition = Petition.trending.first
        signature = FactoryBot.create(:validated_signature, petition: petition)

        expect(Petition.trending.first.signature_count_in_period).to eq(12)

        signature.invalidate!
        expect(Petition.trending.first.signature_count_in_period).to eq(11)
      end
    end

    context "threshold" do
      before :each do
        @p1 = FactoryBot.create(:open_petition, signature_count: Site.threshold_for_debate)
        @p2 = FactoryBot.create(:open_petition, signature_count: Site.threshold_for_debate + 1)
        @p3 = FactoryBot.create(:open_petition, signature_count: Site.threshold_for_debate - 1)
        @p4 = FactoryBot.create(:open_petition, signature_count: Site.threshold_for_debate * 2)
      end

      it "returns 3 petitions over the threshold" do
        petitions = Petition.threshold
        expect(petitions.size).to eq(3)
        expect(petitions).to include(@p1, @p2, @p4)
      end
    end

    context "for_state" do
      before :each do
        @p1 = FactoryBot.create(:petition, :state => Petition::PENDING_STATE)
        @p2 = FactoryBot.create(:petition, :state => Petition::VALIDATED_STATE)
        @p3 = FactoryBot.create(:petition, :state => Petition::PENDING_STATE)
        @p4 = FactoryBot.create(:open_petition, :closed_at => 1.day.from_now)
        @p5 = FactoryBot.create(:petition, :state => Petition::HIDDEN_STATE)
        @p6 = FactoryBot.create(:closed_petition, :closed_at => 1.day.ago)
        @p7 = FactoryBot.create(:petition, :state => Petition::SPONSORED_STATE)
        @p8 = FactoryBot.create(:petition, :state => Petition::FLAGGED_STATE)
      end

      it "returns 2 pending petitions" do
        petitions = Petition.for_state(Petition::PENDING_STATE)
        expect(petitions.size).to eq(2)
        expect(petitions).to include(@p1, @p3)
      end

      it "returns 1 validated, sponsored, flagged, open, closed and hidden petitions" do
        [[Petition::VALIDATED_STATE, @p2], [Petition::OPEN_STATE, @p4],
         [Petition::HIDDEN_STATE, @p5], [Petition::CLOSED_STATE, @p6],
         [Petition::SPONSORED_STATE, @p7], [Petition::FLAGGED_STATE, @p8]].each do |state_and_petition|
          petitions = Petition.for_state(state_and_petition[0])
          expect(petitions.size).to eq(1)
          expect(petitions).to eq([state_and_petition[1]])
        end
      end
    end

    context "visible" do
      before :each do
        @hidden_petition_1 = FactoryBot.create(:petition, :state => Petition::PENDING_STATE)
        @hidden_petition_2 = FactoryBot.create(:petition, :state => Petition::VALIDATED_STATE)
        @hidden_petition_3 = FactoryBot.create(:petition, :state => Petition::HIDDEN_STATE)
        @hidden_petition_4 = FactoryBot.create(:petition, :state => Petition::SPONSORED_STATE)
        @hidden_petition_5 = FactoryBot.create(:petition, :state => Petition::FLAGGED_STATE)
        @visible_petition_1 = FactoryBot.create(:open_petition)
        @visible_petition_2 = FactoryBot.create(:rejected_petition)
        @visible_petition_3 = FactoryBot.create(:open_petition, :closed_at => 1.day.ago)
      end

      it "returns only visible petitions" do
        expect(Petition.visible.size).to eq(3)
        expect(Petition.visible).to include(@visible_petition_1, @visible_petition_2, @visible_petition_3)
      end
    end

    context "current" do
      let!(:petition) { FactoryBot.create(:open_petition) }
      let!(:other_petition) { FactoryBot.create(:open_petition, created_at: 2.week.ago) }
      let!(:closed_petition) { FactoryBot.create(:closed_petition) }
      let!(:rejected_petition) { FactoryBot.create(:rejected_petition) }

      it "doesn't include closed petitions" do
        expect(described_class.current).not_to include(closed_petition)
      end

      it "doesn't include rejected petitions" do
        expect(described_class.current).not_to include(closed_petition)
      end

      it "returns open petitions, newest first" do
        expect(described_class.current).to match_array([petition, other_petition])
      end
    end

    context "not_hidden" do
      let!(:petition) { FactoryBot.create(:hidden_petition) }

      it "returns only petitions that are not hidden" do
        expect(Petition.not_hidden).not_to include(petition)
      end
    end

    context "awaiting_response" do
      context "when the petition has not reached the response threshold" do
        let(:petition) { FactoryBot.create(:open_petition) }

        it "is not included in the list" do
          expect(Petition.awaiting_response).not_to include(petition)
        end
      end

      context "when a petition has reached the response threshold" do
        let(:petition) { FactoryBot.create(:awaiting_petition) }

        it "is included in the list" do
          expect(Petition.awaiting_response).to include(petition)
        end
      end

      context "when a petition has a response" do
        let(:petition) { FactoryBot.create(:responded_petition) }

        it "is not included in the list" do
          expect(Petition.awaiting_response).not_to include(petition)
        end
      end
    end

    context "with_response" do
      before do
        @p1 = FactoryBot.create(:responded_petition)
        @p2 = FactoryBot.create(:open_petition)
        @p3 = FactoryBot.create(:responded_petition)
        @p4 = FactoryBot.create(:open_petition)
      end

      it "returns only the petitions have a government response timestamp" do
        expect(Petition.with_response).to match_array([@p1, @p3])
      end
    end

    context "with_debate_outcome" do
      before do
        @p1 = FactoryBot.create(:debated_petition)
        @p2 = FactoryBot.create(:open_petition)
        @p3 = FactoryBot.create(:debated_petition)
        @p4 = FactoryBot.create(:closed_petition)
        @p5 = FactoryBot.create(:rejected_petition)
        @p6 = FactoryBot.create(:sponsored_petition)
        @p7 = FactoryBot.create(:pending_petition)
        @p8 = FactoryBot.create(:validated_petition)
      end

      it "returns only the petitions which have a debate outcome" do
        expect(Petition.with_debate_outcome).to match_array([@p1, @p3])
      end
    end

    context "with_debated_outcome" do
      before do
        @p1 = FactoryBot.create(:debated_petition)
        @p2 = FactoryBot.create(:open_petition)
        @p3 = FactoryBot.create(:not_debated_petition)
        @p4 = FactoryBot.create(:closed_petition)
        @p5 = FactoryBot.create(:rejected_petition)
        @p6 = FactoryBot.create(:sponsored_petition)
        @p7 = FactoryBot.create(:pending_petition)
        @p8 = FactoryBot.create(:validated_petition)
        @p9 = FactoryBot.create(:open_petition, scheduled_debate_date: 1.day.ago, debate_state: 'debated')
      end

      it "returns only the petitions which have a positive debate outcome" do
        expect(Petition.with_debated_outcome).to match_array([@p1])
      end
    end

    context "awaiting_debate" do
      before do
        @p1 = FactoryBot.create(:open_petition)
        @p2 = FactoryBot.create(:awaiting_debate_petition)
        @p3 = FactoryBot.create(:scheduled_debate_petition, scheduled_debate_date: 2.days.from_now)
        @p4 = FactoryBot.create(:scheduled_debate_petition, scheduled_debate_date: 2.days.ago)
      end

      it "doesn't return petitions that have aren't eligible" do
        expect(Petition.awaiting_debate).not_to include(@p1)
      end

      it "returns petitions that have reached the debate threshold" do
        expect(Petition.awaiting_debate).to include(@p2)
      end

      it "returns petitions that have a scheduled debate date in the future" do
        expect(Petition.awaiting_debate).to include(@p3)
      end

      it "doesn't return petitions that have been debated" do
        expect(Petition.awaiting_debate).not_to include(@p4)
      end
    end

    context "by_most_recent_moderation_threshold_reached" do
      let!(:p1) { FactoryBot.create(:sponsored_petition, moderation_threshold_reached_at: 2.days.ago) }
      let!(:p2) { FactoryBot.create(:sponsored_petition, moderation_threshold_reached_at: 1.day.ago) }

      it "returns the petitions in the correct order" do
        expect(Petition.by_most_recent_moderation_threshold_reached.to_a).to eq([p2, p1])
      end
    end

    context "by_most_relevant_debate_date" do
      before do
        @p1 = FactoryBot.create(:awaiting_debate_petition, debate_threshold_reached_at: 2.weeks.ago)
        @p2 = FactoryBot.create(:awaiting_debate_petition, debate_threshold_reached_at: 4.weeks.ago)
        @p3 = FactoryBot.create(:awaiting_debate_petition, scheduled_debate_date: 4.days.from_now)
        @p4 = FactoryBot.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.from_now)
      end

      it "returns the petitions in the correct order" do
        expect(Petition.by_most_relevant_debate_date.to_a).to eq([@p4, @p3, @p2, @p1])
      end
    end

    context "debated" do
      before do
        @p1 = FactoryBot.create(:open_petition)
        @p2 = FactoryBot.create(:open_petition, scheduled_debate_date: 2.days.from_now)
        @p3 = FactoryBot.create(:awaiting_debate_petition)
        @p4 = FactoryBot.create(:not_debated_petition)
        @p5 = FactoryBot.create(:debated_petition)
      end

      it "doesn't return petitions that have aren't eligible" do
        expect(Petition.debated).not_to include(@p1)
      end

      it "doesn't return petitions that have a scheduled debate date" do
        expect(Petition.debated).not_to include(@p2)
      end

      it "doesn't return petitions that have reached the debate threshold" do
        expect(Petition.debated).not_to include(@p3)
      end

      it "doesn't return petitions that have been rejected for a debate" do
        expect(Petition.debated).not_to include(@p4)
      end

      it "returns petitions that have been debated" do
        expect(Petition.debated).to include(@p5)
      end
    end

    context "not_debated" do
      before do
        @p1 = FactoryBot.create(:open_petition)
        @p2 = FactoryBot.create(:awaiting_debate_petition)
        @p3 = FactoryBot.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.from_now)
        @p4 = FactoryBot.create(:awaiting_debate_petition, scheduled_debate_date: 2.days.ago)
        @p5 = FactoryBot.create(:not_debated_petition)
      end

      it "doesn't return petitions that have aren't eligible" do
        expect(Petition.not_debated).not_to include(@p1)
      end

      it "doesn't return petitions that have reached the debate threshold" do
        expect(Petition.not_debated).not_to include(@p2)
      end

      it "doesn't return petitions that have a scheduled debate date in the future" do
        expect(Petition.not_debated).not_to include(@p3)
      end

      it "doesn't return petitions that have been debated" do
        expect(Petition.not_debated).not_to include(@p4)
      end

      it "returns petitions that have been rejected for a debate" do
        expect(Petition.not_debated).to include(@p5)
      end
    end

    context "awaiting_debate_date" do
      before do
        @p1 = FactoryBot.create(:open_petition)
        @p2 = FactoryBot.create(:awaiting_debate_petition)
        @p3 = FactoryBot.create(:debated_petition)
      end

      it "returns only petitions that reached the debate threshold" do
        expect(Petition.awaiting_debate_date).to include(@p2)
      end

      it "doesn't include petitions that has the debate date" do
        expect(Petition.awaiting_debate_date).not_to include(@p3)
      end
    end

    context "selectable" do
      before :each do
        @non_selectable_petition_1 = FactoryBot.create(:petition, :state => Petition::PENDING_STATE)
        @non_selectable_petition_2 = FactoryBot.create(:petition, :state => Petition::VALIDATED_STATE)
        @non_selectable_petition_3 = FactoryBot.create(:petition, :state => Petition::SPONSORED_STATE)

        @selectable_petition_1 = FactoryBot.create(:open_petition)
        @selectable_petition_2 = FactoryBot.create(:rejected_petition)
        @selectable_petition_3 = FactoryBot.create(:closed_petition, :closed_at => 1.day.ago)
        @selectable_petition_4 = FactoryBot.create(:petition, :state => Petition::HIDDEN_STATE)
      end

      it "returns only selectable petitions" do
        expect(Petition.selectable.size).to eq(4)
        expect(Petition.selectable).to include(@selectable_petition_1, @selectable_petition_2, @selectable_petition_3, @selectable_petition_4)
      end
    end

    context 'in_debate_queue' do
      let!(:petition_1) { FactoryBot.create(:open_petition, debate_threshold_reached_at: 1.day.ago) }
      let!(:petition_2) { FactoryBot.create(:open_petition, debate_threshold_reached_at: nil) }
      let!(:petition_3) { FactoryBot.create(:open_petition, debate_threshold_reached_at: nil, scheduled_debate_date: 3.days.from_now) }
      let!(:petition_4) { FactoryBot.create(:open_petition, debate_threshold_reached_at: nil, scheduled_debate_date: nil) }

      subject { described_class.in_debate_queue }

      it 'includes petitions that have reached the debate threshold' do
        expect(subject).to include(petition_1)
        expect(subject).not_to include(petition_2)
      end

      it 'includes petitions that have not reached the debate threshold if they have been scheduled for debate' do
        expect(subject).to include(petition_3)
        expect(subject).not_to include(petition_4)
      end
    end

    describe '.popular_in_parish' do
      let!(:petition_1) { FactoryBot.create(:open_petition, signature_count: 10) }
      let!(:petition_2) { FactoryBot.create(:open_petition, signature_count: 20) }
      let!(:petition_3) { FactoryBot.create(:open_petition, signature_count: 30) }
      let!(:petition_4) { FactoryBot.create(:open_petition, signature_count: 40) }

      let!(:parish_1) { FactoryBot.generate(:parish_id) }
      let!(:parish_2) { FactoryBot.generate(:parish_id) }

      let!(:petition_1_journal_1) { FactoryBot.create(:parish_petition_journal, petition: petition_1, parish_id: parish_1, signature_count: 6) }
      let!(:petition_1_journal_2) { FactoryBot.create(:parish_petition_journal, petition: petition_1, parish_id: parish_2, signature_count: 4) }
      let!(:petition_2_journal_2) { FactoryBot.create(:parish_petition_journal, petition: petition_2, parish_id: parish_2, signature_count: 20) }
      let!(:petition_3_journal_1) { FactoryBot.create(:parish_petition_journal, petition: petition_3, parish_id: parish_1, signature_count: 30) }
      let!(:petition_4_journal_1) { FactoryBot.create(:parish_petition_journal, petition: petition_4, parish_id: parish_1, signature_count: 0) }
      let!(:petition_4_journal_2) { FactoryBot.create(:parish_petition_journal, petition: petition_4, parish_id: parish_2, signature_count: 40) }

      it 'excludes petitions that have no journal for the supplied parish_id' do
        popular = Petition.popular_in_parish(parish_1, 4)
        expect(popular).not_to include(petition_2)
      end

      it 'excludes petitions that have a journal with 0 votes for the supplied parish_id' do
        popular = Petition.popular_in_parish(parish_1, 4)
        expect(popular).not_to include(petition_4)
      end

      it 'excludes closed petitions with signatures from the supplied parish_id' do
        petition_1.update_columns(state: 'closed', closed_at: 3.days.ago)
        popular = Petition.popular_in_parish(parish_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'excludes rejected petitions with signatures from the supplied parish_id' do
        petition_1.update_column(:state, Petition::REJECTED_STATE)
        popular = Petition.popular_in_parish(parish_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'excludes hidden petitions with signatures from the supplied parish_id' do
        petition_1.update_column(:state, Petition::HIDDEN_STATE)
        popular = Petition.popular_in_parish(parish_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'includes open petitions with signatures from the supplied parish_id ordered by the count of signatures' do
        popular = Petition.popular_in_parish(parish_1, 2)
        expect(popular).to eq [petition_3, petition_1]
      end

      it 'adds the parish_signature_count attribute to the retrieved petitions' do
        most_popular = Petition.popular_in_parish(parish_1, 1).first
        expect(most_popular).to respond_to :parish_signature_count
        expect(most_popular.parish_signature_count).to eq 30
      end

      it 'returns a scope' do
        expect(Petition.popular_in_parish(parish_1, 1)).to be_an ActiveRecord::Relation
      end
    end

    describe '.all_popular_in_parish' do
      let!(:petition_1) { FactoryBot.create(:open_petition, signature_count: 10) }
      let!(:petition_2) { FactoryBot.create(:open_petition, signature_count: 20) }
      let!(:petition_3) { FactoryBot.create(:open_petition, signature_count: 30) }
      let!(:petition_4) { FactoryBot.create(:open_petition, signature_count: 40) }

      let!(:parish_1) { FactoryBot.generate(:parish_id) }
      let!(:parish_2) { FactoryBot.generate(:parish_id) }

      let!(:petition_1_journal_1) { FactoryBot.create(:parish_petition_journal, petition: petition_1, parish_id: parish_1, signature_count: 6) }
      let!(:petition_1_journal_2) { FactoryBot.create(:parish_petition_journal, petition: petition_1, parish_id: parish_2, signature_count: 4) }
      let!(:petition_2_journal_2) { FactoryBot.create(:parish_petition_journal, petition: petition_2, parish_id: parish_2, signature_count: 20) }
      let!(:petition_3_journal_1) { FactoryBot.create(:parish_petition_journal, petition: petition_3, parish_id: parish_1, signature_count: 30) }
      let!(:petition_4_journal_1) { FactoryBot.create(:parish_petition_journal, petition: petition_4, parish_id: parish_1, signature_count: 0) }
      let!(:petition_4_journal_2) { FactoryBot.create(:parish_petition_journal, petition: petition_4, parish_id: parish_2, signature_count: 40) }

      it 'excludes petitions that have no journal for the supplied parish_id' do
        popular = Petition.all_popular_in_parish(parish_1, 4)
        expect(popular).not_to include(petition_2)
      end

      it 'excludes petitions that have a journal with 0 votes for the supplied parish_id' do
        popular = Petition.all_popular_in_parish(parish_1, 4)
        expect(popular).not_to include(petition_4)
      end

      it 'includes closed petitions with signatures from the supplied parish_id' do
        petition_1.update_columns(state: 'closed', closed_at: 3.days.ago)
        popular = Petition.all_popular_in_parish(parish_1, 4)
        expect(popular).to include(petition_1)
      end

      it 'excludes rejected petitions with signatures from the supplied parish_id' do
        petition_1.update_column(:state, Petition::REJECTED_STATE)
        popular = Petition.all_popular_in_parish(parish_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'excludes hidden petitions with signatures from the supplied parish_id' do
        petition_1.update_column(:state, Petition::HIDDEN_STATE)
        popular = Petition.all_popular_in_parish(parish_1, 4)
        expect(popular).not_to include(petition_1)
      end

      it 'includes open petitions with signatures from the supplied parish_id ordered by the count of signatures' do
        popular = Petition.all_popular_in_parish(parish_1, 2)
        expect(popular).to eq [petition_3, petition_1]
      end

      it 'adds the parish_signature_count attribute to the retrieved petitions' do
        most_popular = Petition.all_popular_in_parish(parish_1, 1).first
        expect(most_popular).to respond_to :parish_signature_count
        expect(most_popular.parish_signature_count).to eq 30
      end

      it 'returns a scope' do
        expect(Petition.all_popular_in_parish(parish_1, 1)).to be_an ActiveRecord::Relation
      end
    end

    describe ".in_moderation" do
      let!(:open_petition) { FactoryBot.create(:open_petition) }
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }

      context "with no arguments" do
        it "returns all petitions awaiting moderation" do
          expect(Petition.in_moderation).to include(recent_petition, overdue_petition, nearly_overdue_petition)
        end

        it "doesn't return petitions in other states" do
          expect(Petition.in_moderation).not_to include(open_petition)
        end
      end

      context "with a :from argument" do
        it "returns all petitions awaiting moderation after the timestamp" do
          expect(Petition.in_moderation(from: 5.days.ago)).to include(recent_petition)
        end

        it "doesn't return petitions awaiting moderation before the timestamp" do
          expect(Petition.in_moderation(from: 5.days.ago)).not_to include(overdue_petition, nearly_overdue_petition)
        end

        it "doesn't return petitions in other states" do
          expect(Petition.in_moderation(from: 5.days.ago)).not_to include(open_petition)
        end
      end

      context "with a :to argument" do
        it "returns all petitions awaiting moderation before the timestamp" do
          expect(Petition.in_moderation(to: 7.days.ago)).to include(overdue_petition)
        end

        it "doesn't return petitions awaiting moderation after the timestamp" do
          expect(Petition.in_moderation(to: 7.days.ago)).not_to include(recent_petition, nearly_overdue_petition)
        end

        it "doesn't return petitions in other states" do
          expect(Petition.in_moderation(to: 7.days.ago)).not_to include(open_petition)
        end
      end

      context "with both a :from and :to argument" do
        it "returns all petitions awaiting moderation between the timestamps" do
          expect(Petition.in_moderation(from: 7.days.ago, to: 5.days.ago)).to include(nearly_overdue_petition)
        end

        it "doesn't return petitions awaiting moderation before the timestamp" do
          expect(Petition.in_moderation(from: 7.days.ago, to: 5.days.ago)).not_to include(overdue_petition)
        end

        it "doesn't return petitions awaiting moderation after the timestamp" do
          expect(Petition.in_moderation(from: 7.days.ago, to: 5.days.ago)).not_to include(recent_petition)
        end

        it "doesn't return petitions in other states" do
          expect(Petition.in_moderation(from: 7.days.ago, to: 5.days.ago)).not_to include(open_petition)
        end
      end
    end

    describe ".recently_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }

      it "returns petitions that have recently joined the moderation queue" do
        expect(Petition.recently_in_moderation).to include(recent_petition)
      end

      it "doesn't return petitions that are overdue or nearly overdue" do
        expect(Petition.recently_in_moderation).not_to include(overdue_petition, nearly_overdue_petition)
      end
    end

    describe ".nearly_overdue_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }

      it "returns petitions that are nearly overdue for moderation" do
        expect(Petition.nearly_overdue_in_moderation).to include(nearly_overdue_petition)
      end

      it "doesn't return petitions that are overdue or have recently joined the moderation queue" do
        expect(Petition.nearly_overdue_in_moderation).not_to include(recent_petition, overdue_petition)
      end
    end

    describe ".overdue_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }

      it "returns petitions that are overdue for moderation" do
        expect(Petition.overdue_in_moderation).to include(overdue_petition)
      end

      it "doesn't return petitions that are nearly overdue or have recently joined the moderation queue" do
        expect(Petition.overdue_in_moderation).not_to include(recent_petition, nearly_overdue_petition)
      end
    end

    describe ".tagged_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }
      let!(:tagged_recent_petition) { FactoryBot.create(:sponsored_petition, :recent, :tagged) }
      let!(:tagged_overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue, :tagged) }
      let!(:tagged_nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue, :tagged) }

      it "returns petitions that are in the moderation queue and are tagged" do
        expect(Petition.tagged_in_moderation).to include(tagged_recent_petition, tagged_overdue_petition, tagged_nearly_overdue_petition)
      end

      it "doesn't return petitions that are in the moderation queue but are not tagged" do
        expect(Petition.tagged_in_moderation).not_to include(recent_petition, overdue_petition, nearly_overdue_petition)
      end
    end

    describe ".untagged_in_moderation" do
      let!(:recent_petition) { FactoryBot.create(:sponsored_petition, :recent) }
      let!(:overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue) }
      let!(:nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue) }
      let!(:tagged_recent_petition) { FactoryBot.create(:sponsored_petition, :recent, :tagged) }
      let!(:tagged_overdue_petition) { FactoryBot.create(:sponsored_petition, :overdue, :tagged) }
      let!(:tagged_nearly_overdue_petition) { FactoryBot.create(:sponsored_petition, :nearly_overdue, :tagged) }

      it "returns petitions that are in the moderation queue and are untagged" do
        expect(Petition.untagged_in_moderation).to include(recent_petition, overdue_petition, nearly_overdue_petition)
      end

      it "doesn't return petitions that are in the moderation queue and are tagged" do
        expect(Petition.untagged_in_moderation).not_to include(tagged_recent_petition, tagged_overdue_petition, tagged_nearly_overdue_petition)
      end
    end

    describe ".open_or_signed_since" do
      let(:time) { 10.hours.ago }

      let!(:recent_open_petition_1) { FactoryBot.create :open_petition, open_at: time - 1.minute, action: 'Plant more trees', signature_count: 1, last_signed_at: time + 1.minute }
      let!(:recent_open_petition_2) { FactoryBot.create :open_petition, open_at: time - 1.minute, action: 'Plant more flowers', signature_count: 2, last_signed_at: time + 1.minute }
      let!(:recent_open_petition_3) { FactoryBot.create :open_petition, open_at: time + 1.minute, action: 'Plant more hedges', last_signed_at: nil }

      let!(:recent_rejected_petition) { FactoryBot.create :rejected_petition, open_at: time + 1.minute, action: 'Plant more cabbages' }
      let!(:older_open_petition_signed) { FactoryBot.create :open_petition, open_at: time - 1.minute, action: 'Plant more mushrooms', last_signed_at: time - 1.minute }
      let!(:older_open_petition_unsigned) { FactoryBot.create :open_petition, open_at: time - 1.minute, action: 'Plant more wheat', last_signed_at: nil, increment: false }

      it "returns petitions that have been signed or opened in the supplied period" do
        expect(Petition.open_or_signed_since(time)).to include(recent_open_petition_1, recent_open_petition_2, recent_open_petition_3)
      end

      it "does not return petitions that are non-open or signed outside the period" do
        expect(Petition.open_or_signed_since(time)).to_not include(recent_rejected_petition, older_open_petition_signed, older_open_petition_unsigned)
      end
    end
  end

  it_behaves_like "a taggable model"

  describe "signature count" do
    let(:petition) { FactoryBot.create(:pending_petition) }
    let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      petition.validate_creator!
    end

    it "returns 1 (the creator) for a new petition" do
      expect(petition.signature_count).to eq(1)
    end

    it "still returns 1 with a new signature" do
      signature && petition.reload
      expect(petition.signature_count).to eq(1)
    end

    it "returns 2 when signature is validated" do
      signature.validate! && petition.reload
      expect(petition.signature_count).to eq(2)
    end
  end

  describe 'can_have_debate_added?' do
    it "is true if the petition is OPEN and the closed_at date is in the future" do
      petition = FactoryBot.build(:open_petition, :closed_at => 1.year.from_now)
      expect(petition.can_have_debate_added?).to be_truthy
    end

    it "is true if the petition is OPEN and the closed_at date is in the past" do
      petition = FactoryBot.build(:open_petition, :closed_at => 2.minutes.ago)
      expect(petition.can_have_debate_added?).to be_truthy
    end

    it "is false otherwise" do
      expect(FactoryBot.build(:open_petition, state: Petition::PENDING_STATE).can_have_debate_added?).to be_falsey
      expect(FactoryBot.build(:open_petition, state: Petition::HIDDEN_STATE).can_have_debate_added?).to be_falsey
      expect(FactoryBot.build(:open_petition, state: Petition::REJECTED_STATE).can_have_debate_added?).to be_falsey
      expect(FactoryBot.build(:open_petition, state: Petition::VALIDATED_STATE).can_have_debate_added?).to be_falsey
      expect(FactoryBot.build(:open_petition, state: Petition::SPONSORED_STATE).can_have_debate_added?).to be_falsey
    end
  end

  describe "updating the scheduled debate date" do
    context "when the petition is open" do
      context "and the debate date is changed to nil" do
        subject(:petition) {
          FactoryBot.create(:open_petition,
            scheduled_debate_date: 2.days.from_now,
            debate_state: "scheduled"
          )
        }

        it "sets the debate state to 'awaiting'" do
          expect {
            petition.update(scheduled_debate_date: nil)
          }.to change {
            petition.debate_state
          }.from("scheduled").to("awaiting")
        end
      end

      context "and the debate date is in the future" do
        subject(:petition) {
          FactoryBot.create(:open_petition,
            scheduled_debate_date: nil,
            debate_state: "pending"
          )
        }

        it "sets the debate state to 'awaiting'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.from_now)
          }.to change {
            petition.debate_state
          }.from("pending").to("scheduled")
        end
      end

      context "and the debate date is in the past" do
        subject(:petition) {
          FactoryBot.create(:open_petition,
            scheduled_debate_date: nil,
            debate_state: "pending"
          )
        }

        it "sets the debate state to 'debated'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.ago)
          }.to change {
            petition.debate_state
          }.from("pending").to("debated")
        end
      end

      context "and the debate date is not changed" do
        subject(:petition) {
          FactoryBot.create(:open_petition,
            scheduled_debate_date: Date.yesterday,
            debate_state: "awaiting"
          )
        }

        it "does not change the debate state" do
          expect {
            petition.update(open_at: 5.days.ago)
          }.not_to change {
            petition.debate_state
          }
        end
      end
    end

    context "when the petition is closed" do
      context "and the debate date is changed to nil" do
        subject(:petition) {
          FactoryBot.create(:closed_petition,
            scheduled_debate_date: 2.days.from_now,
            debate_state: "scheduled"
          )
        }

        it "sets the debate state to 'awaiting'" do
          expect {
            petition.update(scheduled_debate_date: nil)
          }.to change {
            petition.debate_state
          }.from("scheduled").to("awaiting")
        end
      end

      context "and the debate date is in the future" do
        subject(:petition) {
          FactoryBot.create(:closed_petition,
            scheduled_debate_date: nil,
            debate_state: "awaiting"
          )
        }

        it "sets the debate state to 'awaiting'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.from_now)
          }.to change {
            petition.debate_state
          }.from("awaiting").to("scheduled")
        end
      end

      context "and the debate date is in the past" do
        subject(:petition) {
          FactoryBot.create(:closed_petition,
            scheduled_debate_date: nil,
            debate_state: "awaiting"
          )
        }

        it "sets the debate state to 'debated'" do
          expect {
            petition.update(scheduled_debate_date: 2.days.ago)
          }.to change {
            petition.debate_state
          }.from("awaiting").to("debated")
        end
      end

      context "and the debate date is not changed" do
        subject(:petition) {
          FactoryBot.create(:closed_petition,
            scheduled_debate_date: Date.yesterday,
            debate_state: "awaiting"
          )
        }

        it "does not change the debate state" do
          expect {
            petition.update(open_at: 5.days.ago)
          }.not_to change {
            petition.debate_state
          }
        end
      end
    end
  end

  describe "#can_be_signed?" do
    context "when the petition is in the open state" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::OPEN_STATE) }

      it "is true" do
        expect(petition.can_be_signed?).to be_truthy
      end
    end

    (Petition::STATES - [Petition::OPEN_STATE]).each do |state|
      context "when the petition is in the #{state} state" do
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is false" do
          expect(petition.can_be_signed?).to be_falsey
        end
      end
    end
  end

  describe "#open?" do
    context "when the state is open" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::OPEN_STATE) }

      it "returns true" do
        expect(petition.open?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::OPEN_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not open when state is #{state}" do
          expect(petition.open?).to be_falsey
        end
      end
    end
  end

  describe "#closed?" do
    context "when the state is closed" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::CLOSED_STATE) }

      it "returns true" do
        expect(petition.closed?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::CLOSED_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not open when state is #{state}" do
          expect(petition.open?).to be_falsey
        end
      end
    end
  end

  describe "#closed_for_signing?" do
    let(:now) { Time.current.change(sec: 0) }
    let(:yesterday) { now - 24.hours }

    context "when the petition closed less than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: yesterday + 1.second) }

      it "returns false" do
        expect(petition.closed_for_signing?(now)).to be_falsey
      end
    end

    context "when the petition closed exactly 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: yesterday) }

      it "returns false" do
        expect(petition.closed_for_signing?(now)).to be_falsey
      end
    end

    context "when the petition closed more than 24 hours ago" do
      let(:petition) { FactoryBot.create(:closed_petition, closed_at: yesterday - 1.second) }

      it "returns true" do
        expect(petition.closed_for_signing?(now)).to be_truthy
      end
    end
  end

  describe "#rejected?" do
    context "when the state is rejected" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::REJECTED_STATE) }

      it "returns true" do
        expect(petition.rejected?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::REJECTED_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not rejected when state is #{state}" do
          expect(petition.rejected?).to be_falsey
        end
      end
    end
  end

  describe "#hidden?" do
    context "when the state is hidden" do
      it "returns true" do
        expect(FactoryBot.build(:petition, :state => Petition::HIDDEN_STATE).hidden?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::HIDDEN_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not hidden when state is #{state}" do
          expect(petition.hidden?).to be_falsey
        end
      end
    end
  end

  describe "#visible?" do
    context "for moderated states" do
      Petition::VISIBLE_STATES.each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is visible when state is #{state}" do
          expect(petition.visible?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::VISIBLE_STATES).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not visible when state is #{state}" do
          expect(petition.visible?).to be_falsey
        end
      end
    end
  end

  describe "#flagged?" do
    context "when the state is flagged" do
      let(:petition) { FactoryBot.build(:petition, state: Petition::FLAGGED_STATE) }

      it "returns true" do
        expect(petition.flagged?).to be_truthy
      end
    end

    context "for other states" do
      (Petition::STATES - [Petition::FLAGGED_STATE]).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not open when state is #{state}" do
          expect(petition.flagged?).to be_falsey
        end
      end
    end
  end

  describe "#in_moderation?" do
    context "for in moderation states" do
      Petition::IN_MODERATION_STATES.each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is in moderation when state is #{state}" do
          expect(petition.in_moderation?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::IN_MODERATION_STATES).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not in moderation when state is #{state}" do
          expect(petition.in_moderation?).to be_falsey
        end
      end
    end
  end

  describe "#moderated?" do
    context "for moderated states" do
      Petition::MODERATED_STATES.each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is moderated when state is #{state}" do
          expect(petition.moderated?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::MODERATED_STATES).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not moderated when state is #{state}" do
          expect(petition.moderated?).to be_falsey
        end
      end
    end
  end

  describe "#in_todo_list?" do
    context "for todo list states" do
      Petition::TODO_LIST_STATES.each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is in todo list when the state is #{state}" do
          expect(petition.in_todo_list?).to be_truthy
        end
      end
    end

    context "for other states" do
      (Petition::STATES - Petition::TODO_LIST_STATES).each do |state|
        let(:petition) { FactoryBot.build(:petition, state: state) }

        it "is not in todo list when the state is #{state}" do
          expect(petition.in_todo_list?).to be_falsey
        end
      end
    end
  end

  describe ".anonymize_petitions!" do
    context "when a petition has closed less than six months ago" do
      let!(:petition) { FactoryBot.create(:closed_petition, closed_at: 5.months.ago) }

      it "does not anonymize the petition" do
        expect{
          perform_enqueued_jobs {
            described_class.anonymize_petitions!
          }
        }.not_to change{ petition.reload.anonymized? }
      end
    end

    context "when a petition has closed more than six months ago" do
      let!(:petition) { FactoryBot.create(:closed_petition, closed_at: 7.months.ago) }

      it "does anonymize the petition" do
        expect{
          perform_enqueued_jobs {
            described_class.anonymize_petitions!
          }
        }.to change{ petition.reload.anonymized? }.from(false).to(true)
      end
    end
  end

  describe ".in_need_of_anonymizing" do
    context "when a petition is anonymized" do
      let!(:petition) { FactoryBot.create(:closed_petition, closed_at: 7.months.ago, anonymized_at: 1.week.ago) }

      it "doesn't return the petition" do
        expect(described_class.in_need_of_anonymizing).not_to include(petition)
      end
    end

    context "when a petition is not anonymized" do
      context "and it has been closed for less than six months" do
        let!(:petition) { FactoryBot.create(:closed_petition, closed_at: 5.months.ago, anonymized_at: nil) }

        it "doesn't return the petition" do
          expect(described_class.in_need_of_anonymizing).not_to include(petition)
        end
      end

      context "and it has been closed for more than six months" do
        let!(:petition) { FactoryBot.create(:closed_petition, closed_at: 7.months.ago, anonymized_at: nil) }

        it "returns the petition" do
          expect(described_class.in_need_of_anonymizing).to include(petition)
        end
      end
    end
  end

  describe "#anonymize!" do
    let(:petition) { FactoryBot.create(:closed_petition, closed_at: "2018-06-30T00:00:00Z") }

    it "enqueues an AnonymizePetitionJob" do
      expect {
        petition.anonymize!("2018-12-31T00:00:00Z".in_time_zone)
      }.to have_enqueued_job(AnonymizePetitionJob)
        .with(petition, "2018-12-31T00:00:00+00:00")
        .on_queue("high_priority")
    end
  end

  describe "#anonymized?" do
    context "when anonymized_at is nil" do
      let(:petition) { FactoryBot.build(:petition, anonymized_at: nil) }

      it "return false" do
        expect(petition.anonymized?).to eq(false)
      end
    end

    context "when anonymized_at is not nil" do
      let(:petition) { FactoryBot.build(:petition, anonymized_at: 1.week.ago) }

      it "return true" do
        expect(petition.anonymized?).to eq(true)
      end
    end
  end

  describe "counting validated signatures" do
    let(:petition) { FactoryBot.build(:petition) }

    it "only counts validated signtatures" do
      expect(petition.signatures).to receive(:validated).and_return(double(:valid_signatures, :count => 123))
      expect(petition.count_validated_signatures).to eq(123)
    end
  end

  describe ".close_petitions!" do
    context "when a petition is in the open state and the closing date has not passed" do
      let(:open_at) { Site.opened_at_for_closing(1.day.from_now) }
      let!(:petition) { FactoryBot.create(:open_petition, open_at: open_at) }

      it "does not close the petition" do
        expect{
          described_class.close_petitions!
        }.not_to change{ petition.reload.state }
      end
    end

    context "when a petition is in the open state and closed_at has passed" do
      let(:open_at) { Site.opened_at_for_closing - 1.day }
      let!(:petition) { FactoryBot.create(:open_petition, open_at: open_at) }

      it "does close the petition" do
        expect{
          described_class.close_petitions!
        }.to change{ petition.reload.state }.from('open').to('closed')
      end
    end
  end

  describe ".in_need_of_closing" do
    context "when a petition is in the closed state" do
      let!(:petition) { FactoryBot.create(:closed_petition) }

      it "does not find the petition" do
        expect(described_class.in_need_of_closing.to_a).not_to include(petition)
      end
    end

    context "when a petition is in the open state and the closing date has not passed" do
      let(:open_at) { Site.opened_at_for_closing(1.day.from_now) }
      let!(:petition) { FactoryBot.create(:open_petition, open_at: open_at) }

      it "does not find the petition" do
        expect(described_class.in_need_of_closing.to_a).not_to include(petition)
      end
    end

    context "when a petition is in the open state and the closing date has passed" do
      let(:open_at) { Site.opened_at_for_closing - 1.day }
      let!(:petition) { FactoryBot.create(:open_petition, open_at: open_at) }

      it "finds the petition" do
        expect(described_class.in_need_of_closing.to_a).to include(petition)
      end
    end
  end

  describe ".in_need_of_marking_as_debated" do
    context "when a petition is not in the the 'awaiting' debate state" do
      let!(:petition) { FactoryBot.create(:open_petition) }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end

    context "when a petition is awaiting a debate date" do
      let!(:petition) {
        FactoryBot.create(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: nil
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end

    context "when a petition is awaiting a debate" do
      let!(:petition) {
        FactoryBot.create(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: 2.days.from_now
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end

    context "when a petition debate date has passed but is still marked as 'awaiting'" do
      let(:petition) {
        FactoryBot.build(:open_petition,
          debate_state: 'awaiting',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        travel_to(2.days.ago) do
          petition.save
        end
      end

      it "finds the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).to include(petition)
      end
    end

    context "when a petition debate date has passed and it marked as 'debated'" do
      let!(:petition) {
        FactoryBot.create(:open_petition,
          debate_state: 'debated',
          scheduled_debate_date: 2.days.ago
        )
      }

      it "does not find the petition" do
        expect(described_class.in_need_of_marking_as_debated.to_a).not_to include(petition)
      end
    end
  end

  describe ".mark_petitions_as_debated!" do
    context "when a petition is in the scheduled debate state and the debate date has passed" do
      let(:petition) {
        FactoryBot.build(:open_petition,
          debate_state: 'scheduled',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        travel_to(2.days.ago) do
          petition.save
        end
      end

      it "marks the petition as debated" do
        expect{
          described_class.mark_petitions_as_debated!
        }.to change{ petition.reload.debate_state }.from('scheduled').to('debated')
      end
    end

    context "when a petition is in the scheduled debate state and the debate date has not passed" do
      let(:petition) {
        FactoryBot.build(:open_petition,
          debate_state: 'scheduled',
          scheduled_debate_date: Date.tomorrow
        )
      }

      before do
        petition.save
      end

      it "does not mark the petition as debated" do
        expect{
          described_class.mark_petitions_as_debated!
        }.not_to change{ petition.reload.debate_state }
      end
    end
  end

  describe ".with_invalid_signature_counts" do
    let!(:petition) { FactoryBot.create(:open_petition, attributes) }

    context "when there are no petitions with invalid signature counts" do
      let(:attributes) { { created_at: 2.days.ago, updated_at: 2.days.ago } }

      it "doesn't return any petitions" do
        expect(described_class.with_invalid_signature_counts).to eq([])
      end
    end

    context "when there are petitions with invalid signature counts" do
      let(:attributes) { { created_at: 2.days.ago, updated_at: 2.days.ago, signature_count: 100 } }

      it "returns the petitions" do
        expect(described_class.with_invalid_signature_counts).to eq([petition])
      end
    end
  end

  describe "#update_signature_count!" do
    let!(:petition) { FactoryBot.create(:open_petition, attributes) }

    context "when there are petitions with invalid signature counts" do
      let(:attributes) { { created_at: 2.days.ago, updated_at: 2.days.ago, signature_count: 100 } }

      it "updates the signature count" do
        expect{
          petition.update_signature_count!
        }.to change{ petition.reload.signature_count }.from(100).to(1)
      end

      it "updates the updated_at timestamp" do
        expect{
          petition.update_signature_count!
        }.to change{ petition.reload.updated_at }.to(be_within(1.second).of(Time.current))
      end
    end
  end

  describe "#increment_signature_count!" do
    let(:signature_count) { 8 }
    let(:debate_state) { "pending" }

    let(:petition) do
      FactoryBot.create(:open_petition, {
        debate_state: debate_state,
        signature_count: signature_count,
        last_signed_at: 2.days.ago,
        updated_at: 2.days.ago,
        creator_attributes: { validated_at: 5.days.ago }
      })
    end

    it "increases the signature count by 1" do
      expect{
        petition.increment_signature_count!
      }.to change{ petition.signature_count }.by(1)
    end

    it "updates the last_signed_at timestamp" do
      petition.increment_signature_count!
      expect(petition.last_signed_at).to be_within(1.second).of(Time.current)
    end

    it "updates the updated_at timestamp" do
      petition.increment_signature_count!
      expect(petition.updated_at).to be_within(1.second).of(Time.current)
    end

    context "when the petition is first sponsored" do
      let(:petition) do
        FactoryBot.create(:pending_petition, {
          signature_count: 0,
          last_signed_at: nil,
          updated_at: 2.days.ago,
          increment: false
        })
      end

      before do
        FactoryBot.create(:validated_signature, petition: petition, sponsor: true, increment: false)
      end

      it "records changes the state from 'pending' to 'validated'" do
        expect {
          petition.increment_signature_count!
        }.to change{
          petition.state
        }.from(Petition::PENDING_STATE).to(Petition::VALIDATED_STATE)
      end
    end

    context "when the signature count crosses the threshold for moderation" do
      let(:signature_count) { 5 }

      before do
        expect(Site).to receive(:threshold_for_moderation).and_return(5)
        FactoryBot.create(:validated_signature, petition: petition, increment: false)
      end

      context "having already been validated by a sponsor" do
        let(:petition) do
          FactoryBot.create(:validated_petition, {
            signature_count: signature_count,
            last_signed_at: 2.days.ago,
            updated_at: 2.days.ago
          })
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.moderation_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "records changes the state from 'validated' to 'sponsored'" do
          expect {
            petition.increment_signature_count!
          }.to change{
            petition.state
          }.from(Petition::VALIDATED_STATE).to(Petition::SPONSORED_STATE)
        end
      end

      context "without having been validated by a sponsor yet" do
        let(:petition) do
          FactoryBot.create(:pending_petition, {
            signature_count: signature_count,
            last_signed_at: 2.days.ago,
            updated_at: 2.days.ago
          })
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.moderation_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "records changes the state from 'validated' to 'sponsored'" do
          expect {
            petition.increment_signature_count!
          }.to change{
            petition.state
          }.from(Petition::PENDING_STATE).to(Petition::SPONSORED_STATE)
        end
      end
    end

    context "when the signature count is higher than the threshold for moderation" do
      let(:signature_count) { 100 }

      before do
        FactoryBot.create(:validated_signature, petition: petition, increment: false)
      end

      context "and moderation_threshold_reached_at is nil" do
        let(:petition) do
          FactoryBot.create(:open_petition, {
            signature_count: signature_count,
            last_signed_at: 2.days.ago,
            updated_at: 2.days.ago,
            moderation_threshold_reached_at: nil
          })
        end

        it "doesn't change the state to sponsored" do
          expect {
            petition.increment_signature_count!
          }.not_to change{ petition.state }
        end

        it "doesn't update the moderation_threshold_reached_at column" do
          expect {
            petition.increment_signature_count!
          }.not_to change{ petition.moderation_threshold_reached_at }
        end
      end
    end

    context "when the signature count crosses the threshold for a response" do
      let(:signature_count) { 9 }

      before do
        expect(Site).to receive(:threshold_for_response).and_return(10)
        FactoryBot.create(:validated_signature, petition: petition, increment: false)
      end

      it "records the time it happened" do
        expect {
          petition.increment_signature_count!
        }.to change {
          petition.response_threshold_reached_at
        }.to be_within(1.second).of(Time.current)
      end
    end

    context "when the petition hasn't been debated" do
      let(:debate_state) { "pending" }

      context "when the signature count crosses the threshold for a debate" do
        let(:signature_count) { 99 }

        before do
          expect(Site).to receive(:threshold_for_debate).and_return(100)
          FactoryBot.create(:validated_signature, petition: petition, increment: false)
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.debate_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "sets the debate_state to 'awaiting'" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.debate_state
          }.from("pending").to("awaiting")
        end
      end
    end

    context "when the petition is awaiting a debate" do
      let(:debate_state) { "awaiting" }

      context "when the signature count crosses the threshold for a debate" do
        let(:signature_count) { 99 }

        before do
          expect(Site).to receive(:threshold_for_debate).and_return(100)
          FactoryBot.create(:validated_signature, petition: petition, increment: false)
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.debate_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "doesn't change debate_state" do
          expect {
            petition.increment_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("awaiting")
        end
      end
    end

    context "when the petition has been debated" do
      let(:debate_state) { "debated" }

      context "when the signature count crosses the threshold for a debate" do
        let(:signature_count) { 99 }

        before do
          expect(Site).to receive(:threshold_for_debate).and_return(100)
          FactoryBot.create(:validated_signature, petition: petition, increment: false)
        end

        it "records the time it happened" do
          expect {
            petition.increment_signature_count!
          }.to change {
            petition.debate_threshold_reached_at
          }.to be_within(1.second).of(Time.current)
        end

        it "doesn't change debate_state" do
          expect {
            petition.increment_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("debated")
        end
      end
    end
  end

  describe "#decrement_signature_count!" do
    let(:signature_count) { 8 }
    let(:debate_state) { 'awaiting' }

    let(:petition) do
      FactoryBot.create(:open_petition, {
        signature_count: signature_count,
        last_signed_at: 2.days.ago,
        updated_at: 2.days.ago,
        response_threshold_reached_at: 2.days.ago,
        debate_threshold_reached_at: 2.days.ago,
        debate_state: debate_state
      })
    end

    it "decreases the signature count by 1" do
      expect{
        petition.decrement_signature_count!
      }.to change{ petition.signature_count }.by(-1)
    end

    it "updates the updated_at timestamp" do
      petition.decrement_signature_count!
      expect(petition.updated_at).to be_within(1.second).of(Time.current)
    end

    context "when the signature count is 1" do
      let(:signature_count) { 1 }

      it "does nothing" do
        expect{
          petition.decrement_signature_count!
        }.not_to change{ petition.signature_count }
      end
    end

    context "when the signature count crosses below the threshold for a response" do
      let(:signature_count) { 10 }

      before do
        expect(Site).to receive(:threshold_for_response).and_return(10)
      end

      it "resets the timestamp" do
        petition.decrement_signature_count!
        expect(petition.response_threshold_reached_at).to be_nil
      end
    end

    context "when the signature count crosses below the threshold for a debate" do
      let(:signature_count) { 100 }

      before do
        expect(Site).to receive(:threshold_for_debate).and_return(100)
      end

      it "resets the timestamp" do
        petition.decrement_signature_count!
        expect(petition.debate_threshold_reached_at).to be_nil
      end

      context "and a debate has not been scheduled" do
        let(:debate_state) { "awaiting" }

        it "sets the debate_state to 'pending'" do
          petition.decrement_signature_count!
          expect(petition.debate_state).to eq("pending")
        end
      end

      context "and a debate has been scheduled" do
        let(:debate_state) { "scheduled" }

        it "doesn't change debated_state" do
          expect {
            petition.decrement_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("scheduled")
        end
      end

      context "and a debate has taken place" do
        let(:debate_state) { "debated" }

        it "doesn't change debated_state" do
          expect {
            petition.decrement_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("debated")
        end
      end

      context "and a debate has not taken place" do
        let(:debate_state) { "not_debated" }

        it "doesn't change debated_state" do
          expect {
            petition.decrement_signature_count!
          }.not_to change {
            petition.debate_state
          }.from("not_debated")
        end
      end
    end
  end

  describe "at_threshold_for_moderation?" do
    context "when moderation_threshold_reached_at is not present" do
      let(:petition) { FactoryBot.create(:validated_petition, signature_count: signature_count) }

      before do
        expect(Site).to receive(:threshold_for_moderation).and_return(5)
      end

      context "and the signature count is less than the threshold" do
        let(:signature_count) { 4 }

        it "is falsey" do
          expect(petition.at_threshold_for_moderation?).to be_falsey
        end
      end

      context "and the signature count is equal than the threshold" do
        let(:signature_count) { 5 }

        it "is truthy" do
          expect(petition.at_threshold_for_moderation?).to be_truthy
        end
      end

      context "and the signature count is more than the threshold" do
        let(:signature_count) { 6 }

        it "is truthy" do
          expect(petition.at_threshold_for_moderation?).to be_truthy
        end
      end
    end

    context "when moderation_threshold_reached_at is present" do
      let(:petition) { FactoryBot.create(:sponsored_petition) }

      before do
        expect(Site).not_to receive(:threshold_for_moderation)
      end

      it "is falsey" do
        expect(petition.at_threshold_for_moderation?).to be_falsey
      end
    end
  end

  describe "at_threshold_for_response?" do
    context "when response_threshold_reached_at is not present" do
      let(:petition) { FactoryBot.create(:open_petition, signature_count: signature_count) }

      before do
        expect(Site).to receive(:threshold_for_response).and_return(10)
      end

      context "and the signature count is 2 or more less than the threshold" do
        let(:signature_count) { 8 }

        it "is falsey" do
          expect(petition.at_threshold_for_response?).to be_falsey
        end
      end

      context "and the signature count is 1 less than the threshold" do
        let(:signature_count) { 9 }

        it "is truthy" do
          expect(petition.at_threshold_for_response?).to be_truthy
        end
      end

      context "and the signature count equal to the threshold" do
        let(:signature_count) { 10 }

        it "is truthy" do
          expect(petition.at_threshold_for_response?).to be_truthy
        end
      end

      context "and the signature count is more than the threshold" do
        let(:signature_count) { 10 }

        it "is truthy" do
          expect(petition.at_threshold_for_response?).to be_truthy
        end
      end
    end

    context "when response_threshold_reached_at is present" do
      let(:petition) { FactoryBot.create(:awaiting_petition) }

      before do
        expect(Site).not_to receive(:threshold_for_response)
      end

      it "is falsey" do
        expect(petition.at_threshold_for_response?).to be_falsey
      end
    end
  end

  describe 'at_threshold_for_debate?' do
    let(:petition) { FactoryBot.create(:petition, signature_count: signature_count) }

    context 'when signature count is 1 less than the threshold' do
      let(:signature_count) { Site.threshold_for_debate - 1 }

      it 'is truthy' do
        expect(petition.at_threshold_for_debate?).to be_truthy
      end
    end

    context 'when signature count is equal to the threshold' do
      let(:signature_count) { Site.threshold_for_debate }

      it 'is truthy' do
        expect(petition.at_threshold_for_debate?).to be_truthy
      end
    end

    context 'when signature count is 1 or more than the threshold' do
      let(:signature_count) { Site.threshold_for_debate + 1 }

      it 'is truthy' do
        expect(petition.at_threshold_for_debate?).to be_truthy
      end
    end

    context 'when signature count is 2 or more less than the threshold' do
      let(:signature_count) { Site.threshold_for_debate - 2 }

      it 'is falsey' do
        expect(petition.at_threshold_for_debate?).to be_falsey
      end
    end

    context 'when the debate_threshold_reached_at is present' do
      let(:petition) { FactoryBot.create(:awaiting_debate_petition) }

      it 'is falsey' do
        expect(petition.at_threshold_for_debate?).to be_falsey
      end
    end
  end

  describe '#publish' do
    subject(:petition) { FactoryBot.create(:petition) }
    let(:now) { Time.current }
    let(:duration) { Site.petition_duration.months }
    let(:closing_date) { (now + duration).end_of_day }

    before do
      petition.publish
    end

    it "sets the state to OPEN" do
      expect(petition.state).to eq(Petition::OPEN_STATE)
    end

    it "sets the open date to now" do
      expect(petition.open_at).to be_within(1.second).of(now)
    end
  end

  describe "#reject" do
    subject(:petition) { FactoryBot.create(:petition) }

    (Rejection::CODES - Rejection::HIDDEN_CODES).each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          petition.reject(code: rejection_code)
          petition.reload
        end

        it "sets rejection.code to '#{rejection_code}'" do
          expect(petition.rejection.code).to eq(rejection_code)
        end

        it "sets Petition#state to 'rejected'" do
          expect(petition.state).to eq("rejected")
        end
      end
    end

    Rejection::HIDDEN_CODES.each do |rejection_code|
      context "when the reason for rejection is #{rejection_code}" do
        before do
          petition.reject(code: rejection_code)
          petition.reload
        end

        it "sets rejection.code to '#{rejection_code}'" do
          expect(petition.rejection.code).to eq(rejection_code)
        end

        it "sets Petition#state to 'hidden'" do
          expect(petition.state).to eq("hidden")
        end
      end
    end

    context "when two moderators reject the petition at the same time" do
      let(:rejection) { petition.reload.rejection }

      it "doesn't raise an ActiveRecord::RecordNotUnique error" do
        expect {
          p1 = described_class.find(petition.id)
          p2 = described_class.find(petition.id)

          expect(p1.rejection).to be_nil
          expect(p1.association(:rejection)).to be_loaded

          expect(p2.rejection).to be_nil
          expect(p2.association(:rejection)).to be_loaded

          p1.reject(code: "duplicate")
          p2.reject(code: "irrelevant")

          expect(rejection.code).to eq("irrelevant")
        }.not_to raise_error
      end
    end
  end

  describe '#close!' do
    subject(:petition) { FactoryBot.create(:open_petition, debate_state: debate_state) }
    let(:now) { Time.current }
    let(:duration) { Site.petition_duration.months }
    let(:closing_date) { (now + duration).end_of_day }
    let(:debate_state) { 'pending' }

    it "sets the state to CLOSED" do
      expect {
        petition.close!(now)
      }.to change {
        petition.state
      }.from(Petition::OPEN_STATE).to(Petition::CLOSED_STATE)
    end

    it "sets the closing date to now" do
      expect {
        petition.close!(now)
      }.to change {
        petition.closed_at
      }.from(nil).to(now)
    end

    %w[pending awaiting scheduled debated not_debated].each do |state|
      context "when the debate state is '#{state}'" do
        let(:debate_state) { state }

        it "doesn't change the debate state" do
          expect {
            petition.close!
          }.not_to change {
            petition.debate_state
          }
        end
      end
    end

    context "when called without an argument" do
      it "sets the closing date to the deadline" do
        expect {
          petition.close!
        }.to change {
          petition.closed_at
        }.from(nil).to(petition.deadline)
      end
    end

    (Petition::STATES - [Petition::OPEN_STATE]).each do |state|
      context "when called on a #{state} petition" do
        subject(:petition) { FactoryBot.create(:"#{state}_petition") }

        it "raises a RuntimeError" do
          expect { petition.close! }.to raise_error(RuntimeError)
        end
      end
    end
  end

  describe '#flag' do
    subject(:petition) { FactoryBot.create(:petition) }

    before do
      petition.flag
    end

    it "sets the state to FLAGGED" do
      expect(petition.state).to eq(Petition::FLAGGED_STATE)
    end
  end

  describe '#deadline' do
    let(:now) { Time.current }

    context 'for closed petitions' do
      let(:closed_at) { now + 1.day }
      subject(:petition) { FactoryBot.build(:closed_petition, closed_at: closed_at) }

      it 'returns the closed_at timestamp' do
        expect(petition.closed_at).to eq closed_at
        expect(petition.deadline).to eq petition.closed_at
      end
    end

    context 'for open petitions' do
      subject(:petition) { FactoryBot.build(:open_petition, open_at: now) }
      let(:duration) { Site.petition_duration.months }
      let(:closing_date) { (now + duration).end_of_day }

      it "returns the end of the day, #{Site.petition_duration} months after the open_at" do
        expect(petition.open_at).to eq now
        expect(petition.deadline).to eq closing_date
      end

      it "prefers any closed_at stamp that has been set" do
        petition.closed_at = now + 1.day
        expect(petition.deadline).not_to eq closing_date
        expect(petition.deadline).to eq petition.closed_at
      end
    end

    context 'for petitions in other states without an open_at' do
      subject(:petition) { FactoryBot.build(:petition, open_at: nil) }
      it 'is nil' do
        expect(petition.deadline).to be_nil
      end
    end
  end

  describe "#validate_creator!" do
    let(:petition) { FactoryBot.create(:pending_petition, attributes) }
    let(:signature) { petition.creator }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    let(:attributes) do
      { created_at: 2.days.ago, updated_at: 2.days.ago }
    end

    it "changes creator signature state to validated" do
      expect {
        petition.validate_creator!
      }.to change { signature.reload.validated? }.from(false).to(true)
    end

    it "increments the signature count" do
      expect {
        petition.validate_creator!
      }.to change { petition.signature_count }.by(1)
    end

    it "timestamps the petition to say it was updated just now" do
      petition.validate_creator!
      expect(petition.updated_at).to be_within(1.second).of(Time.current)
    end

    it "timestamps the petition to say it was last signed at just now" do
      petition.validate_creator!
      expect(petition.last_signed_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#id" do
    let(:petition){ FactoryBot.create(:petition) }

    it "is greater than 100000" do
      expect(petition.id).to be >= 100000
    end
  end

  describe '#has_maximum_sponsors?' do
    %w[pending validated sponsored flagged].each do |state|
      let(:petition) { FactoryBot.create(:"#{state}_petition", sponsor_count: sponor_count, sponsors_signed: sponsors_signed) }

      context "when petition is #{state}" do
        context "and has less than the maximum number of sponsors" do
          let(:sponor_count) { Site.maximum_number_of_sponsors - 1 }
          let(:sponsors_signed) { true }

          it "returns false" do
            expect(petition.has_maximum_sponsors?).to eq(false)
          end
        end

        context "and has the maximum number of sponsors, but none have signed" do
          let(:sponor_count) { Site.maximum_number_of_sponsors }
          let(:sponsors_signed) { false }

          it "returns false" do
            expect(petition.has_maximum_sponsors?).to eq(false)
          end
        end

        context "and has more than the maximum number of sponsors, but none have signed" do
          let(:sponor_count) { Site.maximum_number_of_sponsors + 1 }
          let(:sponsors_signed) { false }

          it "returns false" do
            expect(petition.has_maximum_sponsors?).to eq(false)
          end
        end

        context "and has the maximum number of sponsors and they have signed" do
          let(:sponor_count) { Site.maximum_number_of_sponsors }
          let(:sponsors_signed) { true }

          it "returns true" do
            expect(petition.has_maximum_sponsors?).to eq(true)
          end
        end

        context "and has more than the maximum number of sponsors and they have signed" do
          let(:sponor_count) { Site.maximum_number_of_sponsors + 1 }
          let(:sponsors_signed) { true }

          it "returns true" do
            expect(petition.has_maximum_sponsors?).to eq(true)
          end
        end
      end
    end
  end

  describe 'email requested receipts' do
    it { is_expected.to have_one(:email_requested_receipt).dependent(:destroy) }

    describe '#email_requested_receipt!' do
      let(:petition) { FactoryBot.create(:petition) }

      it 'returns the existing db object if one exists' do
        existing = petition.create_email_requested_receipt
        expect(petition.email_requested_receipt!).to eq existing
      end

      it 'returns a newly created instance if does not already exist' do
        instance = petition.email_requested_receipt!
        expect(instance).to be_present
        expect(instance).to be_a(EmailRequestedReceipt)
        expect(instance.petition).to eq petition
        expect(instance.petition).to be_persisted
      end
    end
  end

  describe '#get_email_requested_at_for' do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:receipt) { petition.email_requested_receipt! }
    let(:the_stored_time) { 6.days.ago }

    it 'returns nil when nothing has been stamped for the supplied name' do
      expect(petition.get_email_requested_at_for('government_response')).to be_nil
    end

    it 'returns the stored timestamp for the supplied name' do
      receipt.update_column('government_response', the_stored_time)
      expect(petition.get_email_requested_at_for('government_response')).to eq the_stored_time
    end
  end

  describe '#set_email_requested_at_for' do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:receipt) { petition.email_requested_receipt! }
    let(:the_stored_time) { 6.days.ago }

    it 'sets the stored timestamp for the supplied name to the supplied time' do
      petition.set_email_requested_at_for('government_response', to: the_stored_time)
      expect(receipt.government_response).to eq the_stored_time
    end

    it 'sets the stored timestamp for the supplied name to the current time if none is supplied' do
      travel_to the_stored_time do
        petition.set_email_requested_at_for('government_response')
        expect(receipt.government_response).to eq Time.current
      end
    end
  end

  describe "#signatures_to_email_for" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:creator) { petition.creator }
    let!(:other_signature) { FactoryBot.create(:validated_signature, petition: petition) }
    let(:petition_timestamp) { 5.days.ago }

    before { petition.set_email_requested_at_for('government_response', to: petition_timestamp) }

    it 'raises an error if the petition does not have an email requested receipt' do
      petition.email_requested_receipt.destroy && petition.reload
      expect { petition.signatures_to_email_for('government_response') }.to raise_error ArgumentError
    end

    it 'raises an error if the petition does not have the requested timestamp in its email requested receipt' do
      petition.email_requested_receipt.update_column('government_response', nil)
      expect { petition.signatures_to_email_for('government_response') }.to raise_error ArgumentError
    end

    it "does not return those that do not want to be emailed" do
      petition.creator.update_attribute(:notify_by_email, false)
      expect(petition.signatures_to_email_for('government_response')).not_to include creator
    end

    it 'does not return unvalidated signatures' do
      other_signature.update_column(:state, Signature::PENDING_STATE)
      expect(petition.signatures_to_email_for('government_response')).not_to include other_signature
    end

    it 'does not return signatures that have a sent timestamp newer than the petitions requested receipt' do
      other_signature.set_email_sent_at_for('government_response', to: petition_timestamp + 1.day)
      expect(petition.signatures_to_email_for('government_response')).not_to include other_signature
    end

    it 'does not return signatures that have a sent timestamp equal to the petitions requested receipt' do
      other_signature.set_email_sent_at_for('government_response', to: petition_timestamp)
      expect(petition.signatures_to_email_for('government_response')).not_to include other_signature
    end

    it 'does return signatures that have a sent timestamp older than the petitions requested receipt' do
      other_signature.set_email_sent_at_for('government_response', to: petition_timestamp - 1.day)
      expect(petition.signatures_to_email_for('government_response')).to include other_signature
    end

    it 'returns signatures that have no sent timestamp, or null for the requested timestamp in their receipt' do
      expect(petition.signatures_to_email_for('government_response')).to match_array [creator, other_signature]
    end
  end

  describe "#fraudulent_domains" do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:signatures) { double(:signatures) }

    let(:domains) do
      { "foo.com" => 2, "bar.com" => 1 }
    end

    before do
      allow(petition).to receive(:signatures).and_return(signatures)
    end

    it "delegates to signatures association and caches the result" do
      expect(signatures).to receive(:fraudulent_domains).once.and_return(domains)
      expect(petition.fraudulent_domains).to eq("foo.com" => 2, "bar.com" => 1)
      expect(petition.fraudulent_domains).to eq("foo.com" => 2, "bar.com" => 1)
    end
  end

  describe "#fraudulent_domains?" do
    let(:petition) { FactoryBot.create(:open_petition) }

    context "when there no fraudulent signatures" do
      it "returns false" do
        expect(petition.fraudulent_domains?).to eq(false)
      end
    end

    context "when there are fraudulent signatures" do
      before do
        FactoryBot.create(:fraudulent_signature, email: "alice@foo.com", petition: petition)
      end

      it "returns true" do
        expect(petition.fraudulent_domains?).to eq(true)
      end
    end
  end

  describe "#update_lock!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "doesn't update the locked_by association" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.update_lock!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.update_lock!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#checkout!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "updates the locked_by association" do
        expect {
          petition.checkout!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(nil).to(current_user)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "returns false" do
        expect(petition.checkout!(current_user)).to eq(false)
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.checkout!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#force_checkout!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "updates the locked_by association" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(nil).to(current_user)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.from(nil).to(be_within(1.second).of(Time.current))
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "updates the locked_by association" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(other_user).to(current_user)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to(be_within(1.second).of(Time.current))
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.force_checkout!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.force_checkout!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "#release!" do
    let(:current_user) { FactoryBot.create(:moderator_user) }

    context "when the petition is not locked" do
      let(:petition) { FactoryBot.create(:petition, locked_by: nil, locked_at: nil) }

      it "doesn't update the locked_by association" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by someone else" do
      let(:other_user) { FactoryBot.create(:moderator_user) }
      let(:petition) { FactoryBot.create(:petition, locked_by: other_user, locked_at: 1.hour.ago) }

      it "doesn't update the locked_by association" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_by
        }
      end

      it "doesn't update the locked_at timestamp" do
        expect {
          petition.release!(current_user)
        }.not_to change {
          petition.reload.locked_at
        }
      end
    end

    context "when the petition is locked by the current user" do
      let(:petition) { FactoryBot.create(:petition, locked_by: current_user, locked_at: 1.hour.ago) }

      it "updates the locked_by association" do
        expect {
          petition.release!(current_user)
        }.to change {
          petition.reload.locked_by
        }.from(current_user).to(nil)
      end

      it "updates the locked_at timestamp" do
        expect {
          petition.release!(current_user)
        }.to change {
          petition.reload.locked_at
        }.to be_nil
      end
    end
  end
end
