module Admin
  class AccessDenied < RuntimeError; end

  class AdminController < ApplicationController
    include Authentication, FlashI18n, FlashRender

    skip_before_action :service_unavailable
    skip_before_action :authenticate

    before_action :set_appsignal_namespace
    before_action :do_not_cache
    before_action :respond_with_forbidden_if_ip_blocked

    layout 'admin'

    def index
    end

    def admin_request?
      true
    end

    private

    def set_appsignal_namespace
      Appsignal.set_namespace("admin")
    end

    def respond_with_forbidden_if_ip_blocked
      if ip_blocked?
        raise AccessDenied, "You are not permitted to access this page"
      end
    end
  end
end
