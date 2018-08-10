require 'rails_helper'

RSpec.describe "API request to show a petition", type: :request, show_exceptions: true do
  let(:petition) { FactoryBot.create :open_petition }
  let(:attributes) { json["data"]["attributes"] }

  let(:access_control_allow_origin) { response.headers['Access-Control-Allow-Origin'] }
  let(:access_control_allow_methods) { response.headers['Access-Control-Allow-Methods'] }
  let(:access_control_allow_headers) { response.headers['Access-Control-Allow-Headers'] }

  describe "format" do
    it "responds to JSON" do
      get "/petitions/#{petition.id}.json"
      expect(response).to be_success
    end

    it "sets CORS headers" do
      get "/petitions/#{petition.id}.json"

      expect(response).to be_success
      expect(access_control_allow_origin).to eq('*')
      expect(access_control_allow_methods).to eq('GET')
      expect(access_control_allow_headers).to eq('Origin, X-Requested-With, Content-Type, Accept')
    end

    it "does not respond to XML" do
      get "/petitions/#{petition.id}.xml"
      expect(response.status).to eq(406)
    end
  end

  describe "links" do
    let(:links) { json["links"] }

    it "returns a link to itself" do
      get "/petitions/#{petition.id}.json"

      expect(response).to be_success
      expect(links).to include("self" => "https://petitions.gov.je/petitions/#{petition.id}.json")
    end
  end

  describe "data" do
    it "returns the petition with the expected fields" do
      get "/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "action" => a_string_matching(petition.action),
          "background" => a_string_matching(petition.background),
          "additional_details" => a_string_matching(petition.additional_details),
          "state" => a_string_matching(petition.state),
          "signature_count" => eq_to(petition.signature_count),
          "opened_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "created_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "updated_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    it "returns the closed_at timestamp if the petition is closed" do
      petition = FactoryBot.create :closed_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "closed_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
        )
      )
    end

    it "includes the rejection section for rejected petitions" do
      petition = \
        FactoryBot.create :rejected_petition,
          rejection_code: "duplicate",
          rejection_details: "This is a duplication of another petition"

      get "/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "rejected_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "rejection" => a_hash_including(
            "code" => "duplicate",
            "details" => "This is a duplication of another petition"
          )
        )
      )
    end

    it "includes the government_response section for petitions with a government_response" do
      petition = \
        FactoryBot.create :responded_petition,
          response_summary: "Summary of what the government said",
          response_details: "Details of what the government said"

      get "/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "ministers_response_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "ministers_response" => a_hash_including(
            "responded_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
            "summary" => "Summary of what the government said",
            "details" => "Details of what the government said",
            "created_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
            "updated_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z])
          )
        )
      )
    end

    it "includes the date and time at which the thresholds were reached" do
      petition = \
        FactoryBot.create :open_petition,
          moderation_threshold_reached_at: 1.month.ago,
          response_threshold_reached_at: 1.weeks.ago,
          debate_threshold_reached_at: 1.day.ago

      get "/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "moderation_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "response_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate_threshold_reached_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
        )
      )
    end

    it "includes the date when a petition is scheduled for a debate" do
      petition = FactoryBot.create :scheduled_debate_petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "scheduled_debate_date" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z])
        )
      )
    end

    it "includes the debate section for petitions that have been debated" do
      petition = \
        FactoryBot.create :debated_petition,
          debated_on: 1.day.ago,
          overview: "What happened in the debate",
          transcript_url: "http://www.publications.parliament.uk/pa/cm201212/cmhansrd/cm120313/debtext/120313-0001.htm#12031360000001",
          video_url: "http://parliamentlive.tv/event/index/da084e18-0e48-4d0a-9aa5-be27f57d5a71?in=16:31:00",
          debate_pack_url: "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2014-1234"

      get "/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "debate_outcome_at" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z]),
          "debate" => a_hash_including(
            "debated_on" => a_string_matching(%r[\A\d{4}-\d{2}-\d{2}\z]),
            "overview" => "What happened in the debate",
            "transcript_url" => "http://www.publications.parliament.uk/pa/cm201212/cmhansrd/cm120313/debtext/120313-0001.htm#12031360000001",
            "video_url" => "http://parliamentlive.tv/event/index/da084e18-0e48-4d0a-9aa5-be27f57d5a71?in=16:31:00",
            "debate_pack_url" => "http://researchbriefings.parliament.uk/ResearchBriefing/Summary/CDP-2014-1234"
          )
        )
      )
    end

    it "includes the signatures by parish data" do
      petition = FactoryBot.create :open_petition

      FactoryBot.create :parish, :st_saviour, id: 1
      FactoryBot.create :parish, :st_clement, id: 2

      FactoryBot.create :parish_petition_journal, parish_id: 1, signature_count: 123, petition: petition
      FactoryBot.create :parish_petition_journal, parish_id: 2, signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes).to match(
        a_hash_including(
          "signatures_by_parish" => a_collection_containing_exactly(
            {
              "name" => "St. Saviour",
              "signature_count" => 123
            },
            {
              "name" => "St. Clement",
              "signature_count" => 456
            }
          )
        )
      )
    end

    it "doesn't include the signatures by parish data in rejected petitions" do
      petition = FactoryBot.create :rejected_petition

      FactoryBot.create :parish, :st_saviour, id: 1
      FactoryBot.create :parish, :st_clement, id: 2

      FactoryBot.create :parish_petition_journal, parish_id: 1, signature_count: 123, petition: petition
      FactoryBot.create :parish_petition_journal, parish_id: 2, signature_count: 456, petition: petition

      get "/petitions/#{petition.id}.json"
      expect(response).to be_success

      expect(attributes.keys).not_to include("signatures_by_parish")
    end
  end
end
