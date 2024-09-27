When /^I follow "([^\"]*)" for "([^\"]*)"$/ do |link_text, target|
  xpath_for_parent_of_target = "//*[.='#{target}']/ancestor::tr"
  with_scope(xpath_for_parent_of_target) do
    click_link(link_text)
  end
end
