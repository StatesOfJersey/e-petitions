require 'postcode_sanitizer'

class ParishApi
  class Cache < ActiveSupport::Cache::Store
    prepend ActiveSupport::Cache::Strategy::LocalCache

    EXCEPTIONS = [
      Savon::HTTPError,
      Savon::SOAPFault,
      Savon::InvalidResponseError,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Errno::EHOSTUNREACH,
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      Errno::ETIMEDOUT,
      Timeout::Error,
      EOFError,
      SocketError
    ]

    def fetch(name, options = nil, &block)
      Postcode.transaction { super(name, options, &block) }
    rescue *EXCEPTIONS => e
      Appsignal.send_exception(e)
      read_entry(name, **options).try(:value)
    end

    def cleanup(options = nil)
      Postcode.expired.delete_all
    end

    def clear(options = nil)
      Postcode.delete_all
    end

    private

    def read_entry(key, options)
      postcode = Postcode.find_by(postcode: key)

      if postcode
        entry = ActiveSupport::Cache::Entry.new(postcode.parish)
        entry.expires_at = postcode.expires_at
        entry
      end
    rescue StandardError => e
      nil
    end

    def write_entry(key, entry, options)
      return false unless entry.value

      postcode = Postcode.find_or_initialize_by(postcode: key)
      postcode.parish = entry.value

      if entry.expires_at
        postcode.expires_at = Time.at(entry.expires_at)
      else
        postcode.expires_at = nil
      end

      postcode.save!

    rescue ActiveRecord::RecordNotUnique => e
      retry
    rescue StandardError => e
      false
    end

    def delete_entry(key, options)
      Postcode.delete(key)
    rescue StandardError => e
      false
    end
  end

  API_KEY       = "PARISH_API_KEY"
  API_WSDL      = "http://caf.digimap.je/API2/Service.asmx?WSDL"
  API_URL       = "http://caf.digimap.je/API2/Service.asmx"
  ADDRESS_FIELD = "PostCode"
  KEY_PATH      = %i[search_response search_result address_list address parish]

  DEFAULTS = { expires_in: 7.days }

  thread_mattr_accessor :savon, instance_accessor: false
  thread_mattr_accessor :store, instance_accessor: false

  class << self
    def before_remove_const
      self.savon = self.store = nil
    end

    def lookup(postcode, options = {})
      postcode = PostcodeSanitizer.call(postcode)

      fetch(postcode, DEFAULTS.merge(options)) do
        response = client.call(:search, message: message(postcode))
        response.body.dig(*KEY_PATH)
      end
    end

    def cleanup
      cache.cleanup
    end

    def clear
      cache.clear
    end

    private

    def client
      self.savon ||= Savon.client(wsdl: API_WSDL)
    end

    def message(postcode)
      { api_key: api_key, address_field: ADDRESS_FIELD, search_text: postcode, max_results: 1 }
    end

    def api_key
      ENV[API_KEY]
    end

    def cache
      self.store ||= Cache.new
    end

    def fetch(postcode, options = nil, &block)
      cache.fetch(postcode, options, &block)
    end
  end
end
