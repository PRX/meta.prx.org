require 'excon'
require 'securerandom'
require 'uri'

module Dovetail
  module DSL
    def unique_agent
      {headers: {'User-Agent': "meta.prx.org tests #{SecureRandom.uuid}"}}
    end

    def get_unique(url)
      Excon.get(url, unique_agent)
    end

    def head_unique(url)
      Excon.head(url, unique_agent)
    end

    def get_redirect_locations(path)
      program = path.split('/').first.gsub('prod_', '')
      unique_filename = "test.#{SecureRandom.uuid}.#{path.split('/').last}"

      redirect = get_unique("#{CONFIG.DOVETAIL_HOST}/#{path}?noImp")
      redirect.status.must_equal 302
      redirect.headers['x-not-impressed'].must_equal 'yes'
      redirect.headers['location'].must_include "/prod_#{program}/"
      location = URI(redirect.headers['location'])
      digest = location.path.split('/')[2]

      prod_redirect = get_unique("#{CONFIG.DOVETAIL_PROD_HOST}/#{path.gsub('prod_', '')}?noImp")
      prod_redirect.status.must_equal 302
      prod_redirect.headers['x-not-impressed'].must_equal 'yes'
      prod_redirect.headers['location'].must_include "/#{program}/"
      prod_location = URI(prod_redirect.headers['location'])

      [
        "#{location.scheme}://#{location.host}/prod_#{program}/#{digest}/#{unique_filename}",
        "#{prod_location.scheme}://#{prod_location.host}/#{program}/#{digest}/#{unique_filename}",
      ]
    end
  end
end
