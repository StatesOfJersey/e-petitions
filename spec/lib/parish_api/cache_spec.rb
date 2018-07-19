require 'rails_helper'

RSpec.describe ParishApi::Cache do
  let(:options) do
    { expires_in: 10.minutes }
  end

  around do |example|
    subject.clear
    example.run
  end

  describe "#fetch" do
    context "when the cache is not set" do
      it "calls the block" do
        expect {
          |b| subject.fetch("JE11AA", options, &b)
        }.to yield_control
      end

      it "writes the value to the cache" do
        expect {
          subject.fetch("JE11AA", options) { "St. Saviour" }
        }.to change {
          Postcode.find_by(postcode: "JE11AA").try(:parish)
        }.from(nil).to("St. Saviour")
      end

      it "returns the value" do
        expect(subject.fetch("JE11AA", options) { "St. Saviour" }).to eq("St. Saviour")
      end

      it "handles exceptions" do
        expect(Postcode).to receive(:find_by).with(postcode: "JE11AA").and_raise(RuntimeError)
        expect(subject.fetch("JE11AA", options) { "St. Saviour" }).to eq("St. Saviour")
      end
    end

    context "when the cache is set" do
      before do
        subject.write("JE11AA", "St. Saviour", options)
      end

      it "doesn't calls the block" do
        expect {
          |b| subject.fetch("JE11AA", options, &b)
        }.not_to yield_control
      end

      it "returns the value" do
        expect(subject.fetch("JE11AA", options) { "St. Saviour" }).to eq("St. Saviour")
      end
    end

    context "when the cache is expired" do
      before do
        Postcode.create!(postcode: "JE11AA", parish: "St. Saviour", created_at: 1.hour.ago, expires_at: 1.hour.ago)
      end

      it "calls the block" do
        expect {
          |b| subject.fetch("JE11AA", options, &b)
        }.to yield_control
      end

      context "and the block returns a value" do
        let(:b) do
          proc { "St. Helier" }
        end

        it "returns the new value" do
          expect(subject.fetch("JE11AA", options, &b)).to eq("St. Helier")
        end

        it "updates the value in the database" do
          expect {
            subject.fetch("JE11AA", options, &b)
          }.to change {
            Postcode.find_by(postcode: "JE11AA").try(:parish)
          }.from("St. Saviour").to("St. Helier")
        end

        it "updates the expires_at timestamp" do
          expect {
            subject.fetch("JE11AA", options, &b)
          }.to change {
            Postcode.find_by(postcode: "JE11AA").try(:expires_at)
          }.to(be_within(1.second).of(10.minutes.from_now))
        end
      end

      context "and the block returns nil" do
        let(:b) do
          proc { nil }
        end

        it "returns nil" do
          expect(subject.fetch("JE11AA", options, &b)).to be_nil
        end

        it "deletes the entry in the database" do
          expect {
            subject.fetch("JE11AA", options, &b)
          }.to change {
            Postcode.exists?(postcode: "JE11AA")
          }.from(true).to(false)
        end
      end

      context "and the block raises an API exception" do
        let(:b) do
          proc { raise Errno::EHOSTUNREACH }
        end

        it "returns the expired value" do
          expect(subject.fetch("JE11AA", options, &b)).to eq("St. Saviour")
        end

        it "doesn't delete the entry in the database" do
          expect {
            subject.fetch("JE11AA", options, &b)
          }.not_to change {
            Postcode.exists?(postcode: "JE11AA")
          }.from(true)
        end

        it "doesn't update the expires_at timestamp" do
          expect {
            subject.fetch("JE11AA", options, &b)
          }.not_to change {
            Postcode.find_by(postcode: "JE11AA").expires_at
          }
        end

        context "when `force: true` is used" do
          let(:options) do
            { force: true, expires_in: 10.minutes }
          end

          it "returns the expired value" do
            expect(subject.fetch("JE11AA", options, &b)).to eq("St. Saviour")
          end

          it "doesn't delete the entry in the database" do
            expect {
              subject.fetch("JE11AA", options, &b)
            }.not_to change {
              Postcode.exists?(postcode: "JE11AA")
            }.from(true)
          end

          it "doesn't update the expires_at timestamp" do
            expect {
              subject.fetch("JE11AA", options, &b)
            }.not_to change {
              Postcode.find_by(postcode: "JE11AA").expires_at
            }
          end
        end
      end
    end
  end

  describe "#read" do
    context "when the cache is not set" do
      it "returns nil" do
        expect(subject.read("JE11AA", options)).to be_nil
      end
    end

    context "when the cache is set" do
      before do
        subject.write("JE11AA", "St. Saviour", options)
      end

      it "returns the value" do
        expect(subject.read("JE11AA", options)).to eq("St. Saviour")
      end
    end

    context "when the cache is expired" do
      before do
        Postcode.create!(postcode: "JE11AA", parish: "St. Saviour", created_at: 1.hour.ago, expires_at: 1.hour.ago)
      end

      it "returns nil" do
        expect(subject.read("JE11AA", options)).to be_nil
      end
    end
  end

  describe "#write" do
    it "writes the value to the cache" do
      expect {
        subject.write("JE11AA", "St. Saviour", options)
      }.to change {
        Postcode.find_by(postcode: "JE11AA").try(:parish)
      }.from(nil).to("St. Saviour")
    end

    it "handles race conditions" do
      postcode = Postcode.find_or_initialize_by(postcode: "JE11AA")
      allow(Postcode).to receive(:find_or_initialize_by).with(postcode: "JE11AA").and_return(postcode)

      original_method = postcode.method(:save!)
      raise_exception = true

      expect(postcode).to receive(:save!).twice do |*args, &block|
        if raise_exception
          raise_exception = false
          raise ActiveRecord::RecordNotUnique
        end

        original_method.call(*args, &block)
      end

      expect(subject.write("JE11AA", "St. Saviour", options)).to be_truthy
    end

    it "handles other exceptions" do
      postcode = Postcode.find_or_initialize_by(postcode: "JE11AA")
      allow(Postcode).to receive(:find_or_initialize_by).with(postcode: "JE11AA").and_return(postcode)

      expect(postcode).to receive(:save!).and_raise(RuntimeError)
      expect(subject.write("JE11AA", "St. Saviour", options)).to be_falsey
    end
  end

  describe "#delete" do
    before do
      subject.write("JE11AA", "St. Saviour", options)
    end

    it "deletes the value from the cache" do
      expect {
        subject.delete("JE11AA", options)
      }.to change {
        Postcode.find_by(postcode: "JE11AA").try(:parish)
      }.from("St. Saviour").to(nil)
    end

    it "handles exceptions when deleting the TTL" do
      expect(Postcode).to receive(:delete).with("JE11AA").and_raise(RuntimeError)
      expect(subject.delete("JE11AA", options)).to be_falsey
    end
  end
end
