require 'email_spec/cucumber'
require 'rspec/core/pending'
require 'capybara/poltergeist'
require 'webrick/httpproxy'

Capybara.javascript_driver = :poltergeist
Capybara.default_max_wait_time = 5
Capybara.server_port = 3443
Capybara.app_host = "https://127.0.0.1:3443"
Capybara.default_host = "https://petitions.gov.je"
Capybara.default_selector = :xpath
Capybara.automatic_label_click = true

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    phantomjs_logger: File.open(File::NULL, 'w'),
    phantomjs_options: [
      '--ignore-ssl-errors=yes',
      '--local-to-remote-url-access=yes',
      '--proxy=127.0.0.1:8443'
    ]
  )
end

Capybara.register_server :jpets do |app, port|
  Jpets::SSLServer.build(app, port)
end

Capybara.server = :jpets

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
  def t(*args)
    I18n.t(*args)
  end
}

World Module.new {
  def strip_tags(html)
    @sanitizer ||= Rails::Html::FullSanitizer.new
    @sanitizer.sanitize(html, encode_special_chars: false)
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
