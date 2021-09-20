require 'excon'
require 'securerandom'
require 'uri'

module Dovetail
  module DSL
    def meta_headers
      {headers: {'User-Agent': "meta.prx.org tests"}}
    end

    def unique_url(url)
      parsed = URI.parse(url)
      query_parts = URI.decode_www_form(String(parsed.query))
      query_parts << ['_v', SecureRandom.uuid]
      parsed.query = URI.encode_www_form(query_parts)
      parsed.to_s
    end

    def get_unique(url)
      Excon.get(unique_url(url), meta_headers)
    end

    def head_unique(url)
      Excon.head(unique_url(url), meta_headers)
    end

    def get_redirect_locations(path)
      redirect = get_unique("#{CONFIG.DOVETAIL_HOST}/#{path}?noImp")
      redirect.status.must_equal 302
      redirect.headers.keys.must_include 'x-depressions'
      location = URI(redirect.headers['location'])

      prod_redirect = get_unique("#{CONFIG.DOVETAIL_PROD_HOST}/#{path}?noImp")
      if prod_redirect.status != 302
        puts "  Arrangement not found: #{CONFIG.DOVETAIL_PROD_HOST}/#{path}?noImp"
      end
      prod_redirect.status.must_equal 302
      prod_redirect.headers.keys.must_include 'x-depressions'
      prod_location = URI(prod_redirect.headers['location'])

      ["#{location}&force", "#{prod_location}&force"]
    end
  end
end
