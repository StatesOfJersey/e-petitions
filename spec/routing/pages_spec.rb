require 'rails_helper'

RSpec.describe "pages", type: :routes do
  describe "routes" do
    it "GET / routes to pages#index" do
      expect({:get => "/"}).to route_to({:controller => "pages", :action => "index"})
    end

    it "GET /help routes to pages#help" do
      expect({:get => "/help"}).to route_to({:controller => "pages", :action => "help"})
    end

    it "should respond to /privacy" do
      expect({:get => "/privacy"}).to route_to({:controller => "pages", :action => "privacy"})
    end
  end

  describe "helpers" do
    it "#home_url generates https://petitions.gov.je/" do
      expect(home_url).to eq("https://petitions.gov.je/")
    end

    it "#help_url generates https://petitions.gov.je/help" do
      expect(help_url).to eq("https://petitions.gov.je/help")
    end

    it "#privacy_url generates https://petitions.gov.je/privacy" do
      expect(privacy_url).to eq("https://petitions.gov.je/privacy")
    end
  end
end
