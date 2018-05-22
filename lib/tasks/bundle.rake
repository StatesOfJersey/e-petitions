namespace :bundle do
  desc "Audit bundle for any known vulnerabilities"
  task :audit do
    system "bundle-audit check --update"
  end
end
