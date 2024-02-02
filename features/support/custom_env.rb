require 'email_spec/cucumber'
require 'rspec/core/pending'
require 'multi_test'
require 'faker'

# Use webmock to disable net connections except for localhost and exceptions
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: 'chromedriver.storage.googleapis.com'
)

MultiTest.disable_autorun

Capybara.javascript_driver = ENV.fetch("JS_DRIVER", "chrome_headless").to_sym
Capybara.default_max_wait_time = 5
Capybara.server_port = 3443
Capybara.app_host = "https://127.0.0.1:3443"
Capybara.default_host = "https://petitions.gov.je"
Capybara.default_selector = :xpath
Capybara.automatic_label_click = true

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.accept_insecure_certs = true

    opts.add_argument('--allow-insecure-localhost')
    opts.add_argument('--window-size=1280,960')
    opts.add_argument('--proxy-server=127.0.0.1:8443')

    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.add_argument('--disable-site-isolation-trials')
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.accept_insecure_certs = true

    opts.add_argument('--headless=new')
    opts.add_argument('--allow-insecure-localhost')
    opts.add_argument('--window-size=1280,960')
    opts.add_argument('--proxy-server=127.0.0.1:8443')

    if File.exist?("/.dockerenv")
      # Running as root inside Docker
      opts.add_argument('--no-sandbox')
      opts.add_argument('--disable-gpu')
      opts.add_argument('--disable-dev-shm-usage')
    end

    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.add_argument('--disable-site-isolation-trials')
  end

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_server :jpets do |app, port|
  Jpets::SSLServer.build(app, port)
end

Capybara.server = :jpets
Capybara.default_normalize_ws = true

pid = Process.spawn('bin/local_proxy', out: 'log/proxy.log', err: 'log/proxy.log')
Process.detach(pid)

at_exit do
  begin
    Process.kill('INT', pid)
  rescue Errno::ESRCH => e
    puts "The local proxy was not detected - check to see if there's an existing process"
  end
end

World Module.new {
  def t(*args, **kwargs)
    I18n.t(*args, **kwargs)
  end
}

World Module.new {
  def strip_tags(html)
    @sanitizer ||= Rails::Html::FullSanitizer.new
    @sanitizer.sanitize(html, encode_special_chars: false)
  end
}

World Module.new {
  def click_details(name)
    if @javascript
      page.find("//details/summary[contains(., '#{name}')]").click
    else
      page.find("//summary[contains(., '#{name}')]/..").click
    end
  end
}

World Module.new {
  def stub_parish_api_wsdl
    stub_request(:get, ParishApi::API_WSDL).to_return(parish_api_response(:ok, "wsdl"))
  end

  def stub_any_parish_api_request
    stub_request(:post, ParishApi::API_URL)
  end

  def stub_parish_api_for(postcode)
    stub_request(:post, ParishApi::API_URL).with(body: /#{postcode}/)
  end

  def parish_api_response(status, body = "no_results", &block)
    status = Rack::Utils.status_code(status)
    headers = { "Content-Type" => "application/xml" }

    if block_given?
      body = block.call
    else
      body = file_fixture("parish_api/#{body}.xml").read
    end

    { status: status, headers: headers, body: body }
  end

  def file_fixture(fixture_name)
    path = Pathname.new(File.join(file_fixture_path, fixture_name))

    if path.exist?
      path
    else
      msg = "the directory '%s' does not contain a file named '%s'"
      raise ArgumentError, msg % [file_fixture_path, fixture_name]
    end
  end
}

World(RejectionHelper)

Cucumber::Rails::World.fixture_path = "#{::Rails.root}/spec/fixtures"
Cucumber::Rails::World.file_fixture_path = "#{::Rails.root}/spec/fixtures"

# run background jobs inline with delayed job
ActiveJob::Base.queue_adapter = :delayed_job
Delayed::Worker.delay_jobs = false


# Monkey patch Cucumber::Rails to accept Capybara 3.x changes
# https://github.com/cucumber/cucumber-rails/commit/286f37f
module Cucumber
  module Rails
    module Capybara
      module JavascriptEmulation
        def click_with_javascript_emulation(*)
          if link_with_non_get_http_method?
            ::Capybara::RackTest::Form.new(driver, js_form(element_node.document, self[:href], emulated_method)).submit(self)
          else
            click_without_javascript_emulation
          end
        end
      end
    end
  end
end
