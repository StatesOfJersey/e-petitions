Then(/^I should see the cookie message$/) do
  expect(page).to have_text('We use cookies to make this service simpler')
end

Then(/^I should not see the cookie message$/) do
  expect(page).not_to have_text('We use cookies to make this service simpler')
end

Given(/^the site is disabled$/) do
  Site.instance.update! enabled: false
end

Given(/^the site is protected$/) do
  Site.instance.update! protected: true, username: "username", password: "password"
end

Given(/^the site has disabled local petitions$/) do
  Site.instance.update! feature_flags: { disable_local_petitions: true }
end

Given(/^the request is not local$/) do
  page.driver.options[:headers] = { "REMOTE_ADDR" => "192.168.1.128" }
end

Then(/^I am asked for a username and password$/) do
  expect(page.status_code).to eq 401
end

Then(/^I will see a 503 error page$/) do
  expect(page.status_code).to eq 503
end

Then(/^I wait for (\d+) ((?:day|week|month|year|)s?)$/) do |duration, period|
  travel_to(Time.current + (duration.to_i.send(period) + 1.second))
end

When(/^I click the shared link$/) do
  expect(@shared_link).not_to be_blank
  visit @shared_link
end

Then(/^I should not index the page$/) do
  expect(page).to have_css('meta[name=robots]', visible: false)
end

Then(/^I should index the page$/) do
  expect(page).not_to have_css('meta[name=robots]', visible: false)
end
