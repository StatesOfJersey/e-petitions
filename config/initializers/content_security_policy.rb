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
      "https://*.google-analytics.com"

    policy.connect_src :self,
      "https://*.google-analytics.com",
      "https://*.govmetric.com",
      "https://stats.g.doubleclick.net"

    policy.script_src :self,
      "https://www.googletagmanager.com",
      "https://*.google-analytics.com",
      "https://*.govmetric.com",
      "'sha256-6mLTVIrVSkIFgIUkng8vgEXtviyBKsQ/aqh8M4VzbbE='"

    policy.style_src :self, :unsafe_inline,
      "https://*.govmetric.com"
  end

  config.content_security_policy_nonce_generator = -> (request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
