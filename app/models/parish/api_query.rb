require 'nokogiri'

class Parish < ActiveRecord::Base
  class ApiQuery
    def fetch(postcode)
       response = client.call(:search, xml: request(postcode))

       parse(response)
     rescue Savon::HTTPError, Savon::SOAPFault, Savon::InvalidResponseError => e
       Appsignal.send_exception(e)
    end

    def self.before_remove_const
      Thread.current[:__api_client__] = nil
    end

    private

    def client
      Thread.current[:__api_client__] ||= Savon.client(wsdl: "http://caf.digimap.je/API2/Service.asmx?WSDL")
    end

    def request(postcode)
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

    def parse(response)
      response.to_hash.dig(:search_response, :search_result, :address_list, :address, :parish)
    end
  end
end
