Before('@javascript') do
  unless page.driver.invalid_element_errors.include?(Selenium::WebDriver::Error::UnknownError)
    page.driver.invalid_element_errors << Selenium::WebDriver::Error::UnknownError
  end
end

Before do
  default_url_options[:protocol] = 'https'
end

Before do
  stub_parish_api_wsdl

  stub_parish_api_for("JE11AA").to_return(parish_api_response(:ok, "st_saviour"))
  stub_parish_api_for("JE19ZZ").to_return(parish_api_response(:ok, "no_results"))

  ParishApi.clear
end

Before do
  RateLimit.first_or_create!(
    burst_rate: 10, burst_period: 60,
    sustained_rate: 20, sustained_period: 300,
    allowed_domains: "example.com", allowed_ips: "127.0.0.1"
  )
end

After do
  Site.reload
  RateLimit.first.update(allowed_ips: "127.0.0.1", blocked_ips: "")
  page.driver.options[:headers] = { "REMOTE_ADDR" => "127.0.0.1" }
end

Before('@admin') do
  Capybara.app_host = 'https://moderate.petitions.gov.je'
  Capybara.default_host = 'https://moderate.petitions.gov.je'
end

Before('not @admin') do
  Capybara.app_host = 'https://petitions.gov.je'
  Capybara.default_host = 'https://petitions.gov.je'
end

Before('@javascript') do
  @javascript = true
end

Before('not @javascript') do
  @javascript = false
end
