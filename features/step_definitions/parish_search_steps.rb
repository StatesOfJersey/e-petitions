Given(/^a parish "(.*?)" is found by postcode "(.*?)"$/) do |parish_name, postcode|
  @parishes ||= {}
  parish = @parishes[parish_name]

  if parish.nil?
    parish = FactoryBot.create(:parish, name: parish_name)
    @parishes[parish.name] = parish
  end

  for_postcode = @parishes[postcode]

  if for_postcode.nil?
    @parishes[postcode] = parish
  elsif for_postcode == parish
    # noop
  else
    raise "Postcode #{postcode} registered for parish #{for_postcode.name} already, can't reassign to #{parish.name}"
  end
end

Given(/^the MP has passed away$/) do
  @mp_passed_away = true
end

Given(/^(a|few|some|many) residents? in "(.*?)" supports? "(.*?)"$/) do |how_many, parish, petition_action|
  petition = Petition.find_by!(action: petition_action)
  parish = @parishes.fetch(parish)
  how_many =
    case how_many
    when 'a' then 1
    when 'few' then 3
    when 'some' then 5
    when 'many' then 10
    end

  how_many.times do
    FactoryBot.create(:pending_signature, petition: petition, parish_id: parish.id).validate!
  end
end

When(/^I search for petitions local to me in "(.*?)"$/) do |postcode|
  @my_parish = @parishes.fetch(postcode)

  if @parish_api_down
    stub_any_parish_api_request.to_return(status: 500)
  else
    stub_parish_api_for(PostcodeSanitizer.call(postcode)).to_return(parish_api_response(:ok){
      <<~XML
        <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
          <soap:Body>
            <SearchResponse xmlns="http://www.digimap.gg/CAF/2.0">
              <SearchResult>
                <ResultCount>2</ResultCount>
                <AddressList>
                  <Address>
                    <CAFID>7026</CAFID>
                    <Active>true</Active>
                    <DeliveryPointID>69314112</DeliveryPointID>
                    <USRN>40001873</USRN>
                    <Timestamp>2008-10-30T00:00:00</Timestamp>
                    <Business/>
                    <POBox/>
                    <SubElementDesc></SubElementDesc>
                    <BuildingName></BuildingName>
                    <LocationOnStreet/>
                    <NameOfTerrace/>
                    <RoadName></RoadName>
                    <ParentRoadName/>
                    <Locality/>
                    <Parish>#{@my_parish.name}</Parish>
                    <Island>Jersey</Island>
                    <PostCode>#{postcode}</PostCode>
                    <Lon></Lon>
                    <Lat></Lat>
                    <X></X>
                    <Y></Y>
                  </Address>
                </AddressList>
              </SearchResult>
            </SearchResponse>
          </soap:Body>
        </soap:Envelope>
      XML
    })
  end

  within :css, '.local-to-you' do
    fill_in "Jersey postcode", with: postcode
    click_on "Search"
  end
end

Then(/^I should see that my fellow parish residents support "(.*?)"$/) do |petition_action|
  petition = Petition.find_by!(action: petition_action)
  all_signature_count = petition.signatures.validated.count
  local_signature_count = petition.signatures.validated.where(parish_id: @my_parish.id).count
  within :css, '.local-petitions' do
    within ".//*#{XPathHelpers.class_matching('petition-item')}[.//a[.='#{petition_action}']]" do
      expect(page).to have_text("#{local_signature_count} #{'signature'.pluralize(local_signature_count)} from #{@my_parish.name}")
      expect(page).to have_text("#{all_signature_count} #{'signature'.pluralize(all_signature_count)} total")
    end
  end
end

Then(/^I should not see that my fellow parish residents support "(.*?)"$/) do |petition_action|
  within :css, '.local-petitions' do |list|
    expect(list).not_to have_selector(".//*#{XPathHelpers.class_matching('petition-item')}[a[.='#{petition_action}']]")
  end
end

Given(/^the parish api is down$/) do
  @parish_api_down = true
end

Then(/^I should see an explanation that my parish couldn't be found$/) do
  expect(page).not_to have_selector(:css, '.local-petitions .petition-item')
  expect(page).to have_content("We couldn't find the postcode")
end

Then(/^I should see an explanation that there are no petitions popular in my parish$/) do
  within(:css, '.local-petitions') do
    expect(page).not_to have_selector(:css, '.petition-item')
    expect(page).to have_content('No petitions are popular in your parish')
  end
end

Then(/^the petitions I see should be ordered by my fellow parish residents level of support$/) do
  within :css, '.local-petitions ol' do
    petitions = page.all(:css, '.petition-item')
    my_parishs_signature_counts = petitions.map { |petition| Integer(petition.text.match(/(\d+) signatures? from/)[1]) }
    expect(my_parishs_signature_counts).to eq my_parishs_signature_counts.sort.reverse
  end
end

Then(/^I should see a link to view all local petitions$/) do
  expect(page).to have_link("View all popular petitions in #{@my_parish.name}", href: all_local_petition_path(@my_parish))
end

Then(/^I should see a link to view open local petitions$/) do
  expect(page).to have_link("View open popular petitions in #{@my_parish.name}", href: local_petition_path(@my_parish))
end

When(/^I click the view all local petitions$/) do
  click_on "View all popular petitions in #{@my_parish.name}"
end

Then(/^I should see that closed petitions are identified$/) do
  expect(page).to have_text("now closed")
end

When(/^I click the JSON link$/) do
  click_on "JSON"
end

Then(/^the JSON should be valid$/) do
  expect { JSON.parse(page.body) }.not_to raise_error
end

When(/^I click the CSV link$/) do
  click_on "CSV"
end
