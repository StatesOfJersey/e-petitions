Given /^a set of petitions$/ do
  3.times do |x|
    @petition = FactoryBot.create(:open_petition, :with_additional_details, :action => "Petition #{x}")
  end
end

Given(/^a set of (\d+) petitions$/) do |number|
  number.times do |x|
    @petition = FactoryBot.create(:open_petition, :with_additional_details, :action => "Petition #{x}")
  end
end

When(/^I navigate to the next page of petitions$/) do
  click_link "Next"
end

Given(/^a(n)? ?(pending|validated|sponsored|flagged|open|rejected)? petition "([^"]*)"$/) do |a_or_an, state, petition_action|
  petition_args = {
    :action => petition_action,
    :closed_at => 1.day.from_now,
    :state => state || "open"
  }
  @petition = FactoryBot.create(:open_petition, petition_args)
end

Given(/^a (sponsored|flagged) petition "(.*?)" reached threshold (\d+) days? ago$/) do |state, action, age|
  @petition = FactoryBot.create(:petition, action: action, state: state, moderation_threshold_reached_at: age.days.ago)
end

Given(/^a petition "([^"]*)" with a negative debate outcome$/) do |action|
  @petition = FactoryBot.create(:not_debated_petition, action: action)
end

Given(/^a(n)? ?(pending|validated|sponsored|open)? petition "([^"]*)" with scheduled debate date of "(.*?)"$/) do |_, state, petition_title, scheduled_debate_date|
  step "an #{state} petition \"#{petition_title}\""
  @petition.scheduled_debate_date = scheduled_debate_date.to_date
  @petition.save
end

Given(/^a petition "([^"]*)" exists with a signature count of (\d+)$/) do |petition_action, count|
  @petition = FactoryBot.create(:open_petition, action: petition_action)
  @petition.update_attribute(:signature_count, count)
end

Given(/^an open petition "(.*?)" with response "(.*?)" and response summary "(.*?)"$/) do |petition_action, details, summary|
  @petition = FactoryBot.create(:responded_petition, action: petition_action, response_details: details, response_summary: summary)
end

Given(/^a ?(open|closed|rejected)? petition "([^"]*)" exists and has received a Ministers response (\d+) days ago$/) do |state, petition_action, parliament_response_days_ago |
  petition_attributes = {
    action: petition_action,
    closed_at: state == 'closed' ? 1.day.ago : 6.months.from_now,
    response_summary: 'Response Summary',
    response_details: "Ministers' Response",
    government_response_at: parliament_response_days_ago.to_i.days.ago
  }
  petition = FactoryBot.create(:responded_petition, petition_attributes)

  if state == "rejected"
    petition.reject(code: "duplicate")
  end
end

Given(/^a petition "(.*?)" exists and hasn't passed the threshold for a ?(response|debate)?$/) do |action, response_or_debate|
  FactoryBot.create(:open_petition, action: action)
end

Given(/^a petition "(.*?)" exists and passed the threshold for a response less than a day ago$/) do |action|
  FactoryBot.create(:open_petition, action: action, response_threshold_reached_at: 2.hours.ago)
end

Given(/^a petition "(.*?)" exists and passed the threshold for a response (\d+) days? ago$/) do |action, amount|
  FactoryBot.create(:open_petition, action: action, response_threshold_reached_at: amount.days.ago)
end

Given(/^a rejected petition "(.*?)" exists and passed the threshold for a response (\d+) days? ago$/) do |action, amount|
  petition = FactoryBot.create(:open_petition, action: action, response_threshold_reached_at: amount.days.ago)
  petition.reject(code: "duplicate")
end

Given(/^a petition "(.*?)" passed the threshold for a debate less than a day ago and has no debate date set$/) do |action|
  petition = FactoryBot.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: 2.hours.ago)
  petition.debate_outcome = nil
end

Given(/^a petition "(.*?)" passed the threshold for a debate (\d+) days? ago and has no debate date set$/) do |action, amount|
  petition = FactoryBot.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: amount.days.ago)
  petition.debate_outcome = nil
end

Given(/^a rejected petition "(.*?)" passed the threshold for a debate (\d+) days? ago and has no debate date set$/) do |action, amount|
  petition = FactoryBot.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: amount.days.ago)
  petition.debate_outcome = nil
  petition.reject(code: "duplicate")
end

Given(/^a petition "(.*?)" passed the threshold for a debate (\d+) days? ago and has a debate in (\d+) days$/) do |action, threshold, debate|
  petition = FactoryBot.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: threshold.days.ago, scheduled_debate_date: debate.days.from_now)
  petition.debate_outcome = nil
end

Given(/^the petition "([^"]*)" has (\d+) validated signatures$/) do |petition_action, no_validated|
  petition = Petition.find_by(action: petition_action)
  (no_validated - 1).times { FactoryBot.create(:validated_signature, petition: petition) }
  petition.reload
  @petition.reload if @petition
end

Given(/^a petition "([^"]*)" has been closed$/) do |petition_action|
  @petition = FactoryBot.create(:closed_petition, :action => petition_action)
end

Given(/^the petition has closed$/) do
  @petition.close!
end

Given(/^the petition has closed some time ago$/) do
  @petition.close!(2.days.ago)
end

Given(/^a petition "([^"]*)" has been rejected(?: with the reason "([^"]*)")?$/) do |petition_action, reason|
  @petition = FactoryBot.create(:rejected_petition,
    :action => petition_action,
    :rejection_code => "irrelevant",
    :rejection_details => reason || "It doesn't make any sense")
end

When(/^I view the petition$/) do
  visit petition_url(@petition)
end

When /^I view all petitions from the home page$/ do
  visit home_url
  click_link "All petitions"
end

When(/^I check for similar petitions$/) do
  fill_in "q", :with => "Rioters should loose benefits"
  click_button("Continue")
end

When(/^I choose to create a petition anyway$/) do
  click_link_or_button "My petition is different"
end

Then(/^I should see all petitions$/) do
  expect(page).to have_css("ol li", :count => 3)
end

Then(/^I should see the petition details$/) do
  expect(page).to have_content(@petition.action)
  expect(page).to have_content(@petition.background) if @petition.background?
  expect(page).to have_content(@petition.additional_details) if @petition.additional_details?
end

Then(/^I should see the vote count, closed and open dates$/) do
  @petition.reload
  expect(page).to have_css("p.signature-count-number", :text => "#{@petition.signature_count} #{'signature'.pluralize(@petition.signature_count)}")

  expect(page).to have_css("li.meta-deadline", :text => "Deadline " + @petition.deadline.strftime("%e %B %Y").squish)
  expect(page).to have_css("li.meta-created-by", :text => "Created by " + @petition.creator.name)
end

Then(/^I should not see the vote count$/) do
  @petition.reload
  expect(page).to_not have_css("p.signature-count-number", :text => @petition.signature_count.to_s + " signatures")
end

Then(/^I should see submitted date$/) do
  @petition.reload
  expect(page).to have_css("li", :text =>  "Date submitted " + @petition.created_at.strftime("%e %B %Y").squish)
end

Then(/^I should not see the petition creator$/) do
  expect(page).not_to have_css("li.meta-created-by", :text => "Created by " + @petition.creator.name)
end

Then(/^I should see the reason for rejection$/) do
  @petition.reload
  expect(page).to have_content(@petition.rejection.details)
end

Then(/^I should be asked to search for a new petition$/) do
  expect(page).to have_content("What do you want us to do?")
  expect(page).to have_css("form textarea[name=q]")
end

Then(/^I should see my search query already filled in as the action of the petition$/) do
  expect(page).to have_field("What do you want us to do?", text: "Rioters should loose benefits")
end

Then(/^I can click on a link to return to the petition$/) do
  expect(page).to have_css("a[href*='/petitions/#{@petition.id}']")
end

When(/^I am allowed to make the petition action too long$/) do
  # NOTE: we do this to remove the maxlength attribtue on the petition
  # action input because any modern browser/driver will not let us enter
  # values longer than maxlength and so we can't test our JS validation
  page.execute_script "document.getElementById('petition_creator_action').removeAttribute('maxlength');"
end

When(/^I start a new petition/) do
  steps %Q(
    Given I am on the new petition page
    Then I should see "Start a petition - Petitions" in the browser page title
    And I should be connected to the server via an ssl connection
  )
end

When(/^I fill in the petition details/) do
  steps %Q(
    When I fill in "What do you want us to do?" with "The wombats of wimbledon rock."
    And I fill in "Background" with "Give half of Wimbledon rock to wombats!"
    And I fill in "Additional details" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  )
end

Then(/^I should see my parish "([^"]*)"/) do |parish|
  expect(page).to have_text(parish)
end

Then(/^I should not see my parish "([^"]*)"/) do |parish|
  expect(page).to_not have_text(parish)
end

Then(/^I should not see the text "([^"]*)"/) do |text|
  expect(page).to_not have_text(text)
end

Then(/^my petition should be validated$/) do
  @sponsor_petition.reload
  expect(@sponsor_petition.state).to eq Petition::VALIDATED_STATE
end

Then(/^the petition creator signature should be validated$/) do
  @sponsor_petition.reload
  expect(@sponsor_petition.creator.state).to eq Signature::VALIDATED_STATE
end

Then(/^I can share it via (.+)$/) do |service|
  case service
  when 'Email'
    within(:css, '.petition-share') do
      expect(page).to have_link('Email', href: %r[\Amailto:\?body=#{ERB::Util.url_encode(petition_url(@petition))}&subject=Petition%3A%20#{ERB::Util.url_encode(@petition.action)}\z])
    end
  when 'Facebook'
    within(:css, '.petition-share') do
      expect(page).to have_link('Facebook', href: %r[\Ahttps://www\.facebook\.com/sharer/sharer\.php\?ref=responsive&u=#{ERB::Util.url_encode(petition_url(@petition))}\z])
    end
  when 'Twitter'
    within(:css, '.petition-share') do
      expect(page).to have_link('Twitter', href: %r[\Ahttps://twitter\.com/intent/tweet\?text=Petition%3A%20#{ERB::Util.url_encode(@petition.action)}&url=#{ERB::Util.url_encode(petition_url(@petition))}\z])
    end
  when 'Whatsapp'
    within(:css, '.petition-share') do
      expect(page).to have_link('Whatsapp', href: %r[\Awhatsapp://send\?text=Petition%3A%20#{ERB::Util.url_encode(@petition.action + "\n" + petition_url(@petition))}\z])
    end
  else
    raise ArgumentError, "Unknown sharing service: #{service.inspect}"
  end
end

Then(/^I expand "([^"]*)"/) do |text|
  page.find("//details/summary[contains(., '#{text}')]").click
end

Given(/^an? (open|closed|rejected) petition "(.*?)" with some (fraudulent)? ?signatures$/) do |state, petition_action, signature_state|
  petition_closed_at = state == 'closed' ? 1.day.ago : nil
  petition_state = state == 'closed' ? 'open' : state
  petition_args = {
    action: petition_action,
    open_at: 3.months.ago,
    closed_at: petition_closed_at
  }
  @petition = FactoryBot.create(:"#{state}_petition", petition_args)
  signature_state ||= "validated"
  5.times { FactoryBot.create(:"#{signature_state}_signature", petition: @petition) }
end

Given(/^the threshold for a states assembly debate is "(.*?)"$/) do |amount|
  Site.instance.update!(threshold_for_debate: amount)
end

Given(/^there are (\d+) petitions awaiting a Ministers response$/) do |response_count|
  response_count.times do |count|
    petition = FactoryBot.create(:awaiting_petition, :action => "Petition #{count}")
  end
end

Given(/^a petition "(.*?)" exists with a debate outcome$/) do |action|
  @petition = FactoryBot.create(:debated_petition, action: action, debated_on: 1.day.ago)
end

Given(/^a petition "(.*?)" exists with a debate outcome and with response threshold met$/) do |action|
  @petition = FactoryBot.create(:debated_petition, action: action, debated_on: 1.day.ago, overview: 'Everyone was in agreement, this petition must be made law!', response_threshold_reached_at: 30.days.ago)
end

Given(/^a petition "(.*?)" exists awaiting debate date$/) do |action|
  @petition = FactoryBot.create(:awaiting_debate_petition, action: action)
end

Given(/^a petition "(.*?)" exists with Ministers response$/) do |action|
  @petition = FactoryBot.create(:responded_petition, action: action)
end

Given(/^a petition "(.*?)" exists awaiting Ministers response$/) do |action|
  @petition = FactoryBot.create(:awaiting_petition, action: action)
end

Given(/^an? ?(pending|validated|sponsored|flagged|open)? petition "(.*?)" exists with tags "([^"]*)"$/) do |state, action, tags|
  tags = tags.split(",").map(&:strip)
  state ||= "open"
  tag_ids = tags.map { |tag| Tag.find_or_create_by(name: tag).id }

  @petition = FactoryBot.create(:open_petition, state: state, action: action, tags: tag_ids)
end

Given(/^there are (\d+) petitions with a scheduled debate date$/) do |scheduled_debate_petitions_count|
  scheduled_debate_petitions_count.times do |count|
    FactoryBot.create(:open_petition, :scheduled_for_debate, action: "Petition #{count}")
  end
end

Given(/^there are (\d+) petitions with enough signatures to require a debate$/) do |debate_threshold_petitions_count|
  debate_threshold_petitions_count.times do |count|
    FactoryBot.create(:awaiting_debate_petition, action: "Petition #{count}")
  end
end

Given(/^a petition "(.*?)" has other parliamentary business$/) do |petition_action|
  @petition = FactoryBot.create(:open_petition, action: petition_action)
  @email = FactoryBot.create(:petition_email,
    petition: @petition,
    subject: "Committee to discuss #{petition_action}",
    body: "The Petition Committee will discuss #{petition_action} on the #{Date.tomorrow}"
  )
end

Then(/^I should see the other business items$/) do
  steps %Q(
    Then I should see "Other parliamentary business"
    And I should see "Committee to discuss #{@petition.action}"
    And I should see "The Petition Committee will discuss #{@petition.action} on the #{Date.tomorrow}"
  )
end

When (/^I search all petitions for "(.*?)"$/) do |search_term|
  within :css, '.search-petitions' do
    fill_in :search, with: search_term
    step %{I press "Search"}
  end
end

When(/^I click to see more details$/) do
  click_details "More details"
end

Then(/^I should see the response "([^"]*)"$/) do |response|
  within :xpath, "//details[summary/.='Read the response in full']/div", visible: true do
    expect(page).to have_content(response)
  end
end

Then(/^I should not see the response "([^"]*)"$/) do |response|
  within :xpath, "//details[summary/.='Read the response in full']" do
    expect(page).to have_no_content(response)
  end
end
