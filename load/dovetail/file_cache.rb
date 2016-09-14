require 'config'
require 'stitch_finder'
require 'filesize'

class FileCache

  def initialize(total, concurrency, per)
     @total, @concurrency, @per = total, concurrency, per
  end

  def load!
    @errors = 0
    check_health!

    puts "\nGetting stitch URLs from #{DOVETAIL_HOST}..."
    @stitches = StitchFinder.new(@total, @per).stitches
    puts "  got #{@stitches.count} stitches"

    puts "\nHEAD requesting stitched files..."
    @concurrency.times.map { request_stitches! }.map(&:join)
    puts "  Done!\n\n"

    check_health!
    abort "\nERROR: got #{@errors} non-200s during stitch requests!" if @errors > 0
  end

  def check_health!
    servers = {}
    threads = 10.times.map do
      Thread.new do
        resp = HTTP.get("#{DOVETAIL_HOST}/health")
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
        resp = HTTP.head("#{DOVETAIL_HOST}/#{path}")
        puts "  #{resp.status} HEAD #{path} (#{(Time.now - start).round}s)"
        @errors += 1 if resp.status != 200
      end
    end
  end

end
