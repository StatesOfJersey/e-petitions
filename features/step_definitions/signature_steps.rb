Then /^I cannot sign the petition$/ do
  expect(page).not_to have_css("a", :text => "Sign")
end

When /^I decide to sign the petition$/ do
  visit petition_url(@petition)
  click_link "Sign this petition"
end

When /^I try to sign$/ do
  click_button "Continue"
end

Then /^I am told to check my inbox to complete signing$/ do
  expect(page).to have_title("Thank you")
  expect(page).to have_content("Check your email")
end

When(/^I confirm my email address(?: again)?$/) do
  steps %Q(
    And I open the email with subject "Please confirm your email address"
    When I click the first link in the email
  )
end

def should_be_signature_count_of(count)
  expect(Petition.find(@petition.id).signature_count).to eq(count)
end

Then /^I should have signed the petition$/ do
  should_be_signature_count_of(2)
end

When /^I fill in my non\-Jersey details$/ do
  step "I fill in my details"
  uncheck "I am a Jersey resident and aged 16 or over"
end

When(/^I fill in my details(?: with email "([^"]+)")?$/) do |email_address|
  email_address ||= "womboid@wimbledon.com"
  steps %Q(
    When I fill in "Name" with "Womboid Wibbledon"
    And I fill in "Email" with "#{email_address}"
    And I check "I am a Jersey resident and aged 16 or over"
    And I fill in my postcode with "JE1 1AA"
    And I check "Email me whenever there’s an update about this petition"
  )
end

When(/^I fill in my details with postcode "(.*?)"?$/) do |postcode|
  steps %Q(
    When I fill in "Name" with "Womboid Wibbledon"
    And I fill in "Email" with "womboid@wimbledon.com"
    And I check "I am a Jersey resident and aged 16 or over"
    And I fill in my postcode with "#{postcode}"
    And I check "Email me whenever there’s an update about this petition"
  )
end

When(/^I fill in my postcode with "(.*?)"$/) do |postcode|
  step %{I fill in "Postcode" with "#{postcode}"}
  sanitized_postcode = PostcodeSanitizer.call(postcode)
  fixture_file = sanitized_postcode == "JE11AA" ? "st_saviour" : "no_results"

end

When /^I fill in my details and sign a petition$/ do
  steps %Q(
    When I go to the new signature page for "Do something!"
    And I should see "Do something! - Sign this petition - Petitions" in the browser page title
    And I should be connected to the server via an ssl connection
    And I fill in my details
    And I try to sign
    And I say I am happy with my email address
    Then I am told to check my inbox to complete signing
    And "womboid@wimbledon.com" should receive 1 email
  )
end

Then(/^I am asked to review my email address$/) do
  expect(page).to have_content 'Make sure this is right'
  expect(page).to have_field('Email')
end

When(/^I change my email address to "(.*?)"$/) do |email_address|
  fill_in 'Email', with: email_address
end

When(/^I say I am happy with my email address$/) do
  click_on "Yes – this is my email address"
end

And "I have already signed the petition with an uppercase email" do
  FactoryBot.create(:signature, name: "Womboid Wibbledon", :petition => @petition,
                     :email => "WOMBOID@WIMBLEDON.COM")
end

And "I have already signed the petition but not validated my email" do
  FactoryBot.create(:pending_signature, name: "Womboid Wibbledon", :petition => @petition,
                     :email => "womboid@wimbledon.com")
end

Given /^Suzie has already signed the petition$/ do
  @suzies_signature = FactoryBot.create(:validated_signature, :petition => @petition, :email => "womboid@wimbledon.com",
         :postcode => "JE1 1AA", :name => "Womboid Wibbledon")
end

Given /^Eric has already signed the petition with Suzies email$/ do
  FactoryBot.create(:validated_signature, :petition => @petition, :email => "womboid@wimbledon.com",
         :postcode => "JE1 1AA", :name => "Eric Wibbledon")
end

Given /^I have signed the petition with a second name$/ do
  FactoryBot.create(:validated_signature, :petition => @petition, :email => "womboid@wimbledon.com",
         :postcode => "JE1 1AA", :name => "Sam Wibbledon")
end

Given(/^Suzie has already signed the petition and validated her email$/) do
  @suzies_signature = FactoryBot.create(:validated_signature, :petition => @petition, :email => "womboid@wimbledon.com",
         :postcode => "JE1 1AA", :name => "Womboid Wibbledon")
end

When(/^Suzie shares the signatory confirmation link with Eric$/) do
  @shared_link = signed_signature_url(@suzies_signature, token: @suzies_signature.perishable_token)
end

When /^I try to sign the petition with the same email address and a different name$/ do
  steps %Q{
    When I decide to sign the petition
    And I fill in my details
    And I fill in "Name" with "Sam Wibbledon"
    And I try to sign
    And I say I am happy with my email address
  }
end

When /^I try to sign the petition with the same email address and the same name$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step "I try to sign"
  step "I say I am happy with my email address"
end

When /^I try to sign the petition with the same email address, a different name, and a different postcode$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step %{I fill in "Name" with "Sam Wibbledon"}
  step %{I fill in my postcode with "JE2 1AA"}
  step "I try to sign"
  step "I say I am happy with my email address"
end

When /^I try to sign the petition with the same email address and a third name$/ do
  step "I decide to sign the petition"
  step "I fill in my details"
  step %{I fill in "Name" with "Sarah Wibbledon"}
  step "I try to sign"
  step "I say I am happy with my email address"
end

Then /^I should have signed the petition after confirming my email address$/ do
  steps %Q(
    And "womboid@wimbledon.com" should receive 1 email
    When I confirm my email address
  )
  should_be_signature_count_of(3)
end

Then /^there should be a "([^"]*)" signature with email "([^"]*)" and name "([^"]*)"$/ do |state, email, name|
  expect(Signature.for_email(email).find_by(name: name, state: state)).not_to be_nil
end

Then /^"([^"]*)" wants to be notified about the petition's progress$/ do |name|
  expect(Signature.find_by(name: name).notify_by_email?).to be_truthy
end

Then /^the signature count (?:stays at|goes up to) (\d+)$/ do |number|
  signatures = @petition.signatures
  expect(signatures.count).to eq number
end
