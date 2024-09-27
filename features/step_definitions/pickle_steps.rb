Given(/^a sysadmin user exists with first_name: "([^"]*)", last_name: "([^"]*)", email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)"$/) do |first_name, last_name, email, password, password_confirmation|
  @user = FactoryBot.create(:sysadmin_user, first_name: first_name, last_name: last_name, email: email, password: password, password_confirmation: password_confirmation)
end

Given(/^a moderator user exists with first_name: "([^"]*)", last_name: "([^"]*)", email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)"$/) do |first_name, last_name, email, password, password_confirmation|
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, email: email, password: password, password_confirmation: password_confirmation)
end

Given(/^a moderator user exists with email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)"$/) do |email, password, password_confirmation|
  @user = FactoryBot.create(:moderator_user, email: email, password: password, password_confirmation: password_confirmation)
end

Given(/^a moderator user exists with email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)", force_password_reset: true$/) do |email, password, password_confirmation|
  @user = FactoryBot.create(:moderator_user, email: email, password: password, password_confirmation: password_confirmation, force_password_reset: true)
end

Given(/^a moderator user exists with email: "([^"]*)", first_name: "([^"]*)", last_name: "([^"]*)"$/) do |email, first_name, last_name|
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, email: email)
end

Given(/^a moderator user exists with email: "([^"]*)", first_name: "([^"]*)", last_name: "([^"]*)", failed_login_count: (\d+)$/) do |email, first_name, last_name, failed_login_count|
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, email: email, failed_login_count: failed_login_count)
end

Given(/^(\d+) moderator users exist$/) do |number|
  number.times do |count|
    FactoryBot.create(:moderator_user)
  end
end

Given(/^(\d+) petitions exist with state: "([^"]*)"$/) do |number, state|
  number.times do |count|
    FactoryBot.create(:petition, state: state)
  end
end

When(/^a moderator user should exist with email: "([^"]*)", failed_login_count: "([^"]*)"$/) do |email, failed_login_count|
  expect(AdminUser.where(email: email, failed_login_count: failed_login_count)).to exist
end

Given(/^a moderator user exists with email: "([^"]*)", first_name: "([^"]*)", last_name: "([^"]*)", failed_login_count: "([^"]*)"$/) do |email, first_name, last_name, failed_login_count|
  @user = FactoryBot.create(:moderator_user, email: email, first_name: first_name, last_name: last_name, failed_login_count: failed_login_count)
end

Then(/^a admin user should not exist with email: "([^"]*)"$/) do |email|
  expect(AdminUser.where(email: email)).not_to exist
end

Given(/^an open petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:open_petition, action: action)
end

Given(/^a rejected petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:rejected_petition, action: action)
end

Given(/^a hidden petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:hidden_petition, action: action)
end

Given(/^a sponsored petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:sponsored_petition, action: action)
end

Then(/^a petition should exist with action: "([^"]*)", state: "([^"]*)"$/) do |action, state|
  expect(Petition.where(action: action, state: state)).to exist
end

Given(/^an sponsored petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:sponsored_petition, action: action)
end

Given(/^an open petition exists with action: "([^"]*)", background: "([^"]*)"$/) do |action, background|
  @petition = FactoryBot.create(:open_petition, action: action, background: background)
end

Given('a closed petition exists with action: {string}') do |action|
  @petition = FactoryBot.create(:closed_petition, action: action)
end

Given(/^a closed petition exists with action: "([^"]*)", closed_at: "([^"]*)"$/) do |action, closed_at|
  @petition = FactoryBot.create(:closed_petition, action: action, closed_at: closed_at)
end

Given(/^a pending petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:pending_petition, action: action)
end

Given(/^a validated petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:validated_petition, action: action)
end

Given('an open petition exists with action: {string}, additional_details: {string}, closed_at: {timestamp}') do |action, additional_details, closed_at|
  @petition = FactoryBot.create(:open_petition, action: action, additional_details: additional_details, closed_at: closed_at)
end

Given('an open petition exists with action: {string}, background: {string}, closed_at: {timestamp}') do |action, background, closed_at|
  @petition = FactoryBot.create(:open_petition, action: action, background: background, closed_at: closed_at)
end

Given('an open petition exists with action: {string}, closed_at: {timestamp}') do |action, closed_at|
  @petition = FactoryBot.create(:open_petition, action: action, closed_at: closed_at)
end

Given(/^(\d+) open petitions exist with action: "([^"]*)"$/) do |number, action|
  number.times do |count|
    FactoryBot.create(:open_petition, action: action)
  end
end

Given(/^an open petition exists with action: "([^"]*)", additional_details: "([^"]*)"$/) do |action, additional_details|
  @petition = FactoryBot.create(:open_petition, action: action, additional_details: additional_details)
end

Given(/^a petition "([^"]*)" exists$/) do |action|
  @petition = FactoryBot.create(:petition, action: action)
end
