require 'rails_helper'

RSpec.describe ParishPetitionJournal, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:parish_petition_journal)).to be_valid
  end

  describe "defaults" do
    it "has 0 for initial signature_count" do
      expect(subject.signature_count).to eq 0
    end
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:petition_id, :parish_id]).unique }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:parish_id) }
    it { is_expected.to validate_length_of(:parish_id).is_at_most(255) }
    it { is_expected.to validate_presence_of(:petition) }
    it { is_expected.to validate_presence_of(:signature_count) }
  end

  describe ".for" do
    let(:petition) { FactoryBot.create(:petition) }
    let(:parish_id) { FactoryBot.generate(:parish_id) }

    context "when there is a journal for the requested petition and parish" do
      let!(:existing_record) { FactoryBot.create(:parish_petition_journal, petition: petition, parish_id: parish_id, signature_count: 30) }

      it "doesn't create a new record" do
        expect {
          described_class.for(petition, parish_id)
        }.not_to change(described_class, :count)
      end

      it "fetches the instance from the DB" do
        fetched = described_class.for(petition, parish_id)
        expect(fetched).to eq(existing_record)
      end
    end

    context "when there is no journal for the requested petition and parish" do
      let!(:journal) { described_class.for(petition, parish_id) }

      it "returns a newly created instance" do
        expect(journal).to be_an_instance_of(described_class)
      end

      it "persists the new instance in the DB" do
        expect(journal).to be_persisted
      end

      it "sets the petition of the new instance to the supplied petition" do
        expect(journal.petition).to eq(petition)
      end

      it "sets the parish_id of the new instance to the supplied parish_id" do
        expect(journal.parish_id).to eq(parish_id)
      end

      it "has 0 for a signature count" do
        expect(journal.signature_count).to eq(0)
      end
    end
  end

  describe ".record_new_signature_for" do
    let(:petition) { FactoryBot.create(:open_petition) }
    let(:parish_id) { FactoryBot.generate(:parish_id) }

    def journal
      described_class.for(petition, parish_id)
    end

    context "when the supplied signature is valid" do
      let(:signature) { FactoryBot.build(:validated_signature, petition: petition, parish_id: parish_id) }
      let(:now) { 1.hour.from_now.change(usec: 0) }

      it "increments the signature_count by 1" do
        expect {
          described_class.record_new_signature_for(signature)
        }.to change { journal.signature_count }.by(1)
      end

      it "updates the updated_at timestamp" do
        expect {
          described_class.record_new_signature_for(signature, now)
        }.to change { journal.updated_at }.to(now)
      end
    end

    context "when the supplied signature is nil" do
      let(:signature) { nil }

      it "does nothing" do
        expect {
          described_class.record_new_signature_for(signature)
        }.not_to change { journal.signature_count }
      end
    end

    context "when the supplied signature has no petition" do
      let(:signature) { FactoryBot.build(:validated_signature, petition: nil, parish_id: parish_id) }

      it "does nothing" do
        expect {
          described_class.record_new_signature_for(signature)
        }.not_to change { journal.signature_count }
      end
    end

    context "when the supplied signature has no parish_id" do
      let(:signature) { FactoryBot.build(:validated_signature, petition: petition, parish_id: nil) }

      it "does nothing" do
        expect {
          described_class.record_new_signature_for(signature)
        }.not_to change { journal.signature_count }
      end
    end

    context "when the supplied signature is not validated" do
      let(:signature) { FactoryBot.build(:pending_signature, petition: petition, parish_id: parish_id) }

      it "does nothing" do
        expect {
          described_class.record_new_signature_for(signature)
        }.not_to change { journal.signature_count }
      end
    end

    context "when no journal exists" do
      let(:signature) { FactoryBot.build(:validated_signature, petition: petition, parish_id: parish_id) }

      it "creates a new journal" do
        expect {
          described_class.record_new_signature_for(signature)
        }.to change(described_class, :count).by(1)
      end
    end
  end

  describe ".invalidate_signature_for" do
    let!(:petition) { FactoryBot.create(:open_petition) }
    let!(:parish_id) { FactoryBot.generate(:parish_id) }
    let!(:journal) { FactoryBot.create(:parish_petition_journal, petition: petition, parish_id: parish_id, signature_count: signature_count) }
    let(:signature_count) { 1 }

    context "when the supplied signature is valid" do
      let(:signature) { FactoryBot.build(:invalidated_signature, petition: petition, parish_id: parish_id) }
      let(:now) { 1.hour.from_now.change(usec: 0) }

      it "decrements the signature_count by 1" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.to change { journal.reload.signature_count }.by(-1)
      end

      it "updates the updated_at timestamp" do
        expect {
          described_class.invalidate_signature_for(signature, now)
        }.to change { journal.reload.updated_at }.to(now)
      end
    end

    context "when the supplied signature is nil" do
      let(:signature) { nil }

      it "does nothing" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.not_to change { journal.reload.signature_count }
      end
    end

    context "when the supplied signature has no petition" do
      let(:signature) { FactoryBot.build(:invalidated_signature, petition: nil, parish_id: parish_id) }

      it "does nothing" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.not_to change { journal.reload.signature_count }
      end
    end

    context "when the supplied signature has no country" do
      let(:signature) { FactoryBot.build(:invalidated_signature, petition: petition, parish_id: nil) }

      it "does nothing" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.not_to change { journal.reload.signature_count }
      end
    end

    context "when the supplied signature is not validated" do
      let(:signature) { FactoryBot.build(:pending_signature, petition: petition, parish_id: parish_id) }

      it "does nothing" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.not_to change { journal.reload.signature_count }
      end
    end

    context "when the signature count is already zero" do
      let(:signature) { FactoryBot.build(:invalidated_signature, petition: petition, parish_id: parish_id) }
      let(:signature_count) { 0 }

      it "does nothing" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.not_to change { journal.reload.signature_count }
      end
    end

    context "when no journal exists" do
      let(:signature) { FactoryBot.build(:invalidated_signature, petition: petition, parish_id: parish_id) }

      before do
        described_class.delete_all
      end

      it "creates a new journal" do
        expect {
          described_class.invalidate_signature_for(signature)
        }.to change(described_class, :count).by(1)
      end
    end
  end

  describe ".reset!" do
    let(:petition_1) { FactoryBot.create(:open_petition, creator_attributes: {parish_id: parish_1}) }
    let(:parish_1) { FactoryBot.generate(:parish_id) }
    let(:petition_2) { FactoryBot.create(:open_petition, creator_attributes: {parish_id: parish_1}) }
    let(:parish_2) { FactoryBot.generate(:parish_id) }

    before do
      described_class.for(petition_1, parish_1).update_attribute(:signature_count, 20)
      described_class.for(petition_1, parish_2).update_attribute(:signature_count, 10)
      described_class.for(petition_2, parish_2).update_attribute(:signature_count, 1)
    end

    context 'when there are no signatures' do
      it 'resets all the counts to 0 or 1 for the creator' do
        described_class.reset!
        expect(described_class.for(petition_1, parish_1).signature_count).to eq 1
        expect(described_class.for(petition_1, parish_2).signature_count).to eq 0
        expect(described_class.for(petition_2, parish_1).signature_count).to eq 1
        expect(described_class.for(petition_2, parish_2).signature_count).to eq 0
      end
    end

    context 'when there are signatures' do
      before do
        4.times { FactoryBot.create(:validated_signature, petition: petition_1, parish_id: parish_1) }
        2.times { FactoryBot.create(:pending_signature, petition: petition_1, parish_id: parish_1) }
        3.times { FactoryBot.create(:validated_signature, petition: petition_1, parish_id: parish_2) }
        2.times { FactoryBot.create(:validated_signature, petition: petition_2, parish_id: parish_1) }
        5.times { FactoryBot.create(:pending_signature, petition: petition_2, parish_id: parish_2) }
      end

      it 'resets the counts to that of the validated signatures for the petition' do
        described_class.reset!
        expect(described_class.for(petition_1, parish_1).signature_count).to eq 5 # +1 for the creator
        expect(described_class.for(petition_1, parish_2).signature_count).to eq 3
        expect(described_class.for(petition_2, parish_1).signature_count).to eq 3 # +1 for the creator
        expect(described_class.for(petition_2, parish_2).signature_count).to eq 0
      end

      it 'does not attempt to journal signatures without parishes' do
        FactoryBot.create(:validated_signature, petition: petition_1, parish_id: nil)
        expect { described_class.reset! }.not_to raise_error
        expect(described_class.find_by(petition: petition_1, parish_id: nil)).to be_nil
      end
    end
  end
end
