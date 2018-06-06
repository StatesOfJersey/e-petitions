require Rails.root.join('spec', 'support', 'parish_api_helper')

include ParishApiHelper

Before do
  default_url_options[:protocol] = 'https'
end

Before do
  stub_parish_api_wsdl

  stub_parish_api_response("JE11AA", File.read("spec/fixtures/parish_api/st_saviour.xml"))
  stub_parish_api_response("JE19ZZ", File.read("spec/fixtures/parish_api/no_results.xml"))
end

Before do
  RateLimit.create!(
    burst_rate: 10, burst_period: 60,
    sustained_rate: 20, sustained_period: 300,
    allowed_domains: "example.com", allowed_ips: "127.0.0.1"
  )
end

After do
  Site.reload
end

Before('@admin') do
  Capybara.app_host = 'https://moderate.petitions.gov.je'
  Capybara.default_host = 'https://moderate.petitions.gov.je'
end

Before('~@admin') do
  Capybara.app_host = 'https://petitions.gov.je'
  Capybara.default_host = 'https://petitions.gov.je'
end
