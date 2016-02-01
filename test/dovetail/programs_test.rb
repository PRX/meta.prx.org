require 'test_helper'
require 'digest'

describe 'dovetail-programs' do

  MAX_RETRIES = 5

  EPISODES = {
    '99pi'     => '99pi/190-Fixing-the-Hobo-Suit.mp3',
    'criminal' => 'criminal/23166e58-e181-4c03-b52d-6f6746a1bced/Episode_35__Pen_and_Paper.mp3',
    'memory'   => 'memory/c9dfaa10-7b21-4804-9d5e-7f55dfbefc24/thememorypalace.mp3',
    'serial'   => 'serial/b10f2326-b3b9-478e-a74d-22c460946316/serial-s02-e05.mp3',
  }

  def http_unique
    HTTP.headers('user-agent' => "meta.prx.org tests #{SecureRandom.uuid}")
  end

  # find the same stitch in both new and old (prod) environments
  def get_stitch_in_both_envs(name, path, attempt = 1)
    redirect = http_unique.get("#{DOVETAIL_HOST}/#{path}?noImp")
    redirect.status.must_equal 302
    redirect.headers['x-not-impressed'].must_equal 'yes'
    redirect.headers['location'].must_include "/#{name}/"
    location = "/+/#{name}/" + redirect.headers['location'].split("/#{name}/").last

    # attempt to get prod version
    prod_stitch = HTTP.get(DOVETAIL_PROD + location)
    if prod_stitch.status == 404 && attempt < MAX_RETRIES
      warn "  stitch #{location} not found in prod - retrying ..."
      return get_stitch_in_both_envs(name, path, attempt + 1)
    else
      stitch = HTTP.get(DOVETAIL_HOST + location)
      return [stitch, prod_stitch]
    end
  end

  EPISODES.each do |name, path|

    describe name do

      it 'matches the production mp3' do
        new_stitch, old_stitch = get_stitch_in_both_envs(name, path)
        new_stitch.status.must_equal 200
        new_stitch.headers['content-disposition'].must_equal 'attachment'
        new_stitch.headers['content-type'].must_equal 'audio/mpeg'
        old_stitch.status.must_equal 200
        old_stitch.headers['content-disposition'].must_equal 'attachment'
        old_stitch.headers['content-type'].must_equal 'audio/mpeg'

        tmp_dir = "#{File.dirname(__FILE__)}/../../tmp"
        new_file = "#{tmp_dir}/#{name}.new.mp3"
        old_file = "#{tmp_dir}/#{name}.old.mp3"
        Dir.mkdirp(tmp_dir) unless Dir.exists?(tmp_dir)
        File.open(new_file, 'wb') {|f| f.write(new_stitch.body) }
        File.open(old_file, 'wb') {|f| f.write(old_stitch.body) }

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

end
