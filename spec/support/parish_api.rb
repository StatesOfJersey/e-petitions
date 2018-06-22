RSpec.configure do |config|
  helpers = Module.new do
    def stub_parish_api_wsdl
      stub_request(:get, ParishApi::API_WSDL).to_return(parish_api_response(:ok, "wsdl"))
    end

    def stub_any_parish_api_request
      stub_request(:post, ParishApi::API_URL)
    end

    def stub_parish_api_for(postcode)
      stub_request(:post, ParishApi::API_URL).with(body: /#{postcode}/)
    end

    def parish_api_response(status, body = "no_results", &block)
      status = Rack::Utils.status_code(status)
      headers = { "Content-Type" => "application/xml" }

      if block_given?
        body = block.call
      else
        body = file_fixture("parish_api/#{body}.xml").read
      end

      { status: status, headers: headers, body: body }
    end
  end

  config.include(helpers)

  config.before do
    stub_parish_api_wsdl

    stub_parish_api_for("JE11AA").to_return(parish_api_response(:ok, "st_saviour"))
    stub_parish_api_for("JE19ZZ").to_return(parish_api_response(:ok, "no_results"))

    ParishApi.clear
  end
end
