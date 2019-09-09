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
      stag_program = path.split('/').first
      prod_program = stag_program.gsub('prod_', '')
      prod_path = path.gsub('prod_', '')
      has_prefix = stag_program != prod_program

      unique_filename = "test.#{SecureRandom.uuid}.#{path.split('/').last}"

      redirect = get_unique("#{CONFIG.DOVETAIL_HOST}/#{path}?noImp")
      redirect.status.must_equal 302
      redirect.headers['x-not-impressed'].must_equal 'yes'
      redirect.headers['location'].must_include "/#{stag_program}/"
      location = URI(redirect.headers['location'])
      digest = location.path.split('/')[2]

      prod_redirect = get_unique("#{CONFIG.DOVETAIL_PROD_HOST}/#{prod_path}?noImp")
      if prod_redirect.status != 302
        puts "  Arrangement not found: #{CONFIG.DOVETAIL_PROD_HOST}/#{prod_path}?noImp"
      end
      prod_redirect.status.must_equal 302
      prod_redirect.headers['x-not-impressed'].must_equal 'yes'
      prod_redirect.headers['location'].must_include "/#{prod_program}/"
      prod_location = URI(prod_redirect.headers['location'])

      [
        "#{location.scheme}://#{location.host}/#{stag_program}/#{digest}/#{unique_filename}",
        "#{prod_location.scheme}://#{prod_location.host}/#{prod_program}/#{digest}/#{unique_filename}",
      ]
    end
  end
end
