# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.object_src  :none

    policy.img_src :self,
      "https://*.govmetric.com",
      "https://*.google-analytics.com",
      "https://www.google.com",
      "https://www.google.co.uk",
      "https://www.facebook.com"

    policy.frame_src :self,
      "https://consentcdn.cookiebot.com"

    policy.connect_src :self,
      "https://*.google-analytics.com",
      "https://*.govmetric.com",
      "https://stats.g.doubleclick.net",
      "https://consentcdn.cookiebot.com",
      "https://r1.trackedweb.net"

    policy.script_src :self,
      "https://www.googletagmanager.com",
      "https://*.google-analytics.com",
      "https://*.govmetric.com",
      "https://consent.cookiebot.com",
      "https://consentcdn.cookiebot.com",
      "https://connect.facebook.net",
      "http://static.trackedweb.net",
      "'sha256-mIxSZhYvydb3bb/WRxfU47u0yNgvJfNbFPYxUdGcyhU='",
      "'sha256-eGYiITZn6r/AFy6QrgbyoM4yk3yS1Vo+xgt8ue86jX0='",
      "'sha256-0A1tzz8+V8RNwqXqQafCMU2Ro3lZAPemg4O8wAJxrOc='",
      "'sha256-0N4uBNF8Ck58plVdc/HPoTS5KnKsV2l4tIn14GCP7NE='"

    policy.style_src :self, :unsafe_inline,
      "https://*.govmetric.com"
  end

  config.content_security_policy_nonce_generator = -> (request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
