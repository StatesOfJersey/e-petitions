module ParishApiHelper
  def stub_parish_api_wsdl
    stub_request(:get, "http://caf.digimap.je/API2/Service.asmx?WSDL").
      to_return(
        status: 200,
        body: File.read("spec/fixtures/parish_api/wsdl.xml")
      )
  end

  def stub_parish_api_response(postcode, response_body, response_code=200)
    stub_request(:post, "http://caf.digimap.je/API2/Service.asmx").with(body: expected_request_xml(postcode)).
        to_return(
            status: response_code,
            body: response_body
        )
  end

  def stub_any_api_request
    stub_request(:post, "http://caf.digimap.je/API2/Service.asmx")
  end

  def expected_request_xml(postcode)
    <<~XML
      <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ns="http://www.digimap.gg/CAF/2.0">
         <soap:Header/>
         <soap:Body>
            <ns:Search>
               <ns:apiKey>#{ENV["PARISH_API_KEY"]}</ns:apiKey>
               <ns:addressField>PostCode</ns:addressField>
               <ns:searchText>#{postcode}</ns:searchText>
               <ns:maxResults>1</ns:maxResults>
            </ns:Search>
         </soap:Body>
      </soap:Envelope>
    XML
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(ParishApiHelper)

    config.before do
      stub_parish_api_wsdl

      stub_parish_api_response("JE11AA", File.read("spec/fixtures/parish_api/st_saviour.xml"))
      stub_parish_api_response("JE19ZZ", File.read("spec/fixtures/parish_api/no_results.xml"))
    end
  end
end
