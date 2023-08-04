Then /^the markup should be valid$/ do
  expect(Nokogiri::HTML5(page.source).errors).to be_empty
end
