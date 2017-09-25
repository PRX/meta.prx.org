require 'config'
require 'stitch_finder'
require 'filesize'
require 'json'

class FileCache

  def initialize(total, concurrency, per)
     @total, @concurrency, @per = total, concurrency, per
  end

  def load!
    @errors = 0
    @caches = {}
    check_health!

    puts "\nGetting stitch URLs from #{CONFIG.DOVETAIL_HOST}..."
    @stitches = StitchFinder.new(@total, @per).stitches
    puts "  got #{@stitches.count} stitches"

    puts "\nHEAD requesting stitched files..."
    @concurrency.times.map { request_stitches! }.map(&:join)
    puts "  Done!\n\n"

    puts "\nCaches:"
    @caches.each do |key, count|
      puts "  #{key} = #{count}"
    end
    puts ""

    check_health!
    abort "\nERROR: got #{@errors} non-200s during stitch requests!" if @errors > 0
  end

  def check_health!
    servers = {}
    threads = 10.times.map do
      Thread.new do
        resp = Excon.get("#{CONFIG.DOVETAIL_HOST}/health")
        json = JSON.parse(resp.body)
        servers[json['uuid']] = json['filecache']
      end
    end
    threads.map(&:join)
    puts "Found #{servers.keys.count} servers:"
    servers.each do |key, info|
      count = info['count']
      size = Filesize.from("#{info['usage']} B").pretty
      pct = (info['pct'] * 100).round(1)
      puts "  #{count} files - #{size} - #{pct}%"
    end
  end

  def request_stitches!
    Thread.new do
      while path = @stitches.shift
        start = Time.now
        resp = Excon.head("#{CONFIG.DOVETAIL_HOST}#{path}")
        puts "  #{resp.status} HEAD #{path} (#{(Time.now - start).round}s)"
        if resp.headers['x-proxy-cache']
          @caches[resp.headers['x-proxy-cache']] ||= 0
          @caches[resp.headers['x-proxy-cache']] += 1
        else
          @caches['NOPROXY'] ||= 0
          @caches['NOPROXY'] += 1
        end
        @errors += 1 if resp.status != 200
      end
    end
  end

end
