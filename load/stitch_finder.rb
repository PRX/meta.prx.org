require 'nokogiri'
require 'open-uri'
require 'dovetail_dsl'

# get stitch urls for a bunch of dovetail episodes
class StitchFinder
  include Dovetail::DSL

  ENCLOSURE_TOKEN = 'dovetail.prxu.org'

  DOVETAIL_REQUEST_LIMIT = 10

  # TODO: this really only works if feeder_host is staging
  DOVETAIL_FEEDS = [
    "#{CONFIG.FEEDER_HOST}/podcasts/23", # 99pi
    "#{CONFIG.FEEDER_HOST}/podcasts/13", # serial
    "#{CONFIG.FEEDER_HOST}/podcasts/24", # themoth
    "#{CONFIG.FEEDER_HOST}/podcasts/18", # criminal
    "#{CONFIG.FEEDER_HOST}/podcasts/3",  # memory
  ]

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
        Nokogiri::HTML(open(feed)).xpath('//enclosure/@url').each do |link|
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
          resp = get_unique("#{CONFIG.DOVETAIL_HOST}/#{path}?noImp")
          if resp.status == 404
            path.gsub!(/^\//, '/prod_') # try the prod_ program key
            resp = get_unique("#{CONFIG.DOVETAIL_HOST}/#{path}?noImp")
          end
          if resp.status != 302
            puts "error: #{resp.status} from #{path}"
          elsif resp.headers['Location'][0..2] == '/+/'
            locations << resp.headers['Location']
          elsif resp.headers['Location'] =~ /^.+cdn[^.]*.prxu\.org\//
            locations << resp.headers['Location'].gsub(/^.+cdn[^.]*.prxu\.org\//, '/+/')
          elsif resp.headers['Location'].include? 'dovetail.serialpodcast.org'
            locations << resp.headers['Location'].gsub(/^.+dovetail\.serialpodcast\.org\//, '/+/')
          else
            # unrecognized redirect
          end
        end
      end
    end
    threads.map(&:join)
    locations
  end

end
