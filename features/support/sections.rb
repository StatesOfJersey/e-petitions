module SectionHelpers
  def xpath_of_section(section_name, prefix = "//")
    case section_name

    # Non site-specific based
    when /"([^\"]*)" fieldset/
      "#{prefix}fieldset#{XPathHelpers.class_matching($1.downcase.gsub(/\s/, '_'))}"

    # Sitewide
    when /^single h1$/
      expect(page).to have_xpath("//h1", :count => 1)
      "#{prefix}h1"

    # Home page
    when /^response threshold section$/
      expect(page).to have_xpath("//section[@aria-labelledby='response-threshold-heading']")
      "#{prefix}section[@aria-labelledby='response-threshold-heading']"

    when /^debate threshold section$/
      expect(page).to have_xpath("//section[@aria-labelledby='debate-threshold-heading']")
      "#{prefix}section[@aria-labelledby='debate-threshold-heading']"

    else
      raise "Can't find mapping from \"#{section_name}\" to a section."
    end
  end

  def within_section(section_name)
    within xpath_of_section(section_name) do
      yield
    end
  end
end

World(SectionHelpers)
