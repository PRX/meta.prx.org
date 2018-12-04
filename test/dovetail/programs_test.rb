require 'test_helper'
require 'digest'

describe 'dovetail-programs' do
  include Dovetail::DSL

  EPISODES = {
    'test_feeder_two_segment' => 'test_feeder_two_segment/2097919b-f33a-4437-aacf-bd08abb2e91b/test.mp3',
  }
  EPISODE_THREADS = {}
  EPISODE_RESPONSES = {}
  EPISODE_FILES = {}

  def tmp_file(program, filename)
    tmp_dir = "#{File.dirname(__FILE__)}/../../tmp"
    Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)
    "#{tmp_dir}/#{program}.#{filename}"
  end

  # stitch/download upfront to speed things up
  before do
    if EPISODE_THREADS.empty?
      EPISODES.each do |name, path|
        loc, prod_loc = get_redirect_locations(path)
        EPISODE_THREADS[name] = Thread.new do
          EPISODE_RESPONSES[name] = [nil, nil]
          EPISODE_FILES[name] = [tmp_file(name, 'new.mp3'), tmp_file(name, 'old.mp3')]
          t1 = Thread.new do
            EPISODE_RESPONSES[name][0] = Excon.get(loc)
            File.open(EPISODE_FILES[name][0], 'wb') {|f| f.write(EPISODE_RESPONSES[name][0].body) }
          end
          t2 = Thread.new do
            EPISODE_RESPONSES[name][1] = Excon.get(prod_loc)
            File.open(EPISODE_FILES[name][1], 'wb') {|f| f.write(EPISODE_RESPONSES[name][1].body) }
          end
          [t1, t2].each {|t| t.join}
        end
      end
    end
  end

  EPISODES.each do |name, path|

    it "#{name} matches the production mp3" do
      EPISODE_THREADS[name].join

      new_stitch, old_stitch = EPISODE_RESPONSES[name]
      new_file, old_file = EPISODE_FILES[name]

      new_stitch.status.must_equal 200
      new_stitch.headers['content-disposition'].must_match(/^attachment/)
      new_stitch.headers['content-type'].must_equal 'audio/mpeg'
      new_stitch.headers['x-cache'].must_include 'Miss'
      old_stitch.status.must_equal 200
      old_stitch.headers['content-disposition'].must_match(/^attachment/)
      old_stitch.headers['content-type'].must_equal 'audio/mpeg'
      new_stitch.headers['x-cache'].must_include 'Miss'

      # compare the ffprobe output first
      new_probe = `ffprobe #{new_file} 2>&1`.gsub(/.+#{name}.new.mp3':\n/m, '')
      old_probe = `ffprobe #{old_file} 2>&1`.gsub(/.+#{name}.old.mp3':\n/m, '')
      new_probe_no_encoder = new_probe.gsub(/encoder\s+: (.+)$/, '')
      old_probe_no_encoder = old_probe.gsub(/encoder\s+: (.+)$/, '')

      # allow encoder to differ, but warn loudly
      if new_probe != old_probe && new_probe_no_encoder == old_probe_no_encoder
        new_encoder = new_probe.match(/encoder\s+: (.+)$/)[1]
        old_encoder = old_probe.match(/encoder\s+: (.+)$/)[1]
        msg = "WARNING: encoder changed from #{old_encoder} to #{new_encoder}"
        warn "  #{'=' * msg.length}\n  #{msg}\n  #{'=' * msg.length}"
      else
        new_probe.must_equal old_probe

        # check for identical binary files
        new_sha = Digest::SHA256.file new_file
        old_sha = Digest::SHA256.file old_file
        new_sha.must_equal old_sha
      end
    end

  end

end
