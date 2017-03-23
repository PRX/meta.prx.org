require 'excon'
require 'securerandom'

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
  end
end
