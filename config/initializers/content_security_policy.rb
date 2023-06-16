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
      "https://*.govmetric.com"

    policy.script_src :self, :unsafe_inline,
      "https://www.googletagmanager.com",
      "https://*.google-analytics.com",
      "https://*.govmetric.com"

    policy.style_src :self, :unsafe_inline,
      "https://*.govmetric.com"
  end
end
