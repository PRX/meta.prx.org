require 'nokogiri'
require 'open-uri'

# get stitch urls for a bunch of dovetail episodes
class StitchFinder

  ENCLOSURE_TOKEN = 'dovetail.prxu.org'

  DOVETAIL_REQUEST_LIMIT = 10

  DOVETAIL_FEEDS = %w(
    http://feeds.millennialpodcast.org/millennialpodcast
    http://feeds.serialpodcast.org/serialpodcast
    http://feeds.themoth.org/themothpodcast
    http://feeds.feedburner.com/CriminalShow
    http://feeds.99percentinvisible.org/99percentinvisible
  )

  attr_reader :stitches

  def initialize(episode_count = 10, per = 1)
    episodes = load_enclosures.sample(episode_count)
    @stitches = load_stitches(episodes, per)
  end

  private

  def load_enclosures
    enclosures = []
    threads = DOVETAIL_FEEDS.map do |feed|
      Thread.new do
        Nokogiri::HTML(open(feed)).xpath('//origenclosurelink/text()').each do |link|
          if link.to_s.include?(ENCLOSURE_TOKEN)
            enclosures << link.to_s.split(ENCLOSURE_TOKEN).last
          end
        end
      end
    end
    threads.map(&:join)
    enclosures
  end

  def load_stitches(paths, per)
    locations = []
    threads = []

    # run dovetail requests n-at-a-time
    paths.each do |path|
      per.times do
        if threads.count >= DOVETAIL_REQUEST_LIMIT
          threads.map(&:join)
          threads = []
        end
        threads << Thread.new do
          resp = http_unique.get("#{DOVETAIL_HOST}/#{path}?noImp")
          locations << resp.headers['Location'] if resp.headers['Location'][0..2] == '/+/'
        end
      end
    end
    threads.map(&:join)
    locations
  end

  def http_unique
    HTTP.headers('user-agent' => "meta.prx.org tests #{SecureRandom.uuid}")
  end

end
