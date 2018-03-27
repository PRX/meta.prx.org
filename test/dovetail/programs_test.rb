require 'test_helper'
require 'digest'

describe 'dovetail-programs' do
  include Dovetail::DSL

  EPISODES = {
    'criminal' => 'prod_criminal/23166e58-e181-4c03-b52d-6f6746a1bced/Episode_35__Pen_and_Paper.mp3',
    'memory'   => 'prod_memory/c9dfaa10-7b21-4804-9d5e-7f55dfbefc24/thememorypalace.mp3',
    'serial'   => 'prod_serial/b10f2326-b3b9-478e-a74d-22c460946316/serial-s02-e05.mp3',
  }
  NEW_THREADS = {}
  NEW_DOWNLOADS = {}
  PROD_THREADS = {}
  PROD_DOWNLOADS = {}

  def tmp_file(program, filename)
    tmp_dir = "#{File.dirname(__FILE__)}/../../tmp"
    Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)
    "#{tmp_dir}/#{program}.#{filename}"
  end

  before do
    if NEW_THREADS.empty?
      EPISODES.each do |name, path|
        redirect = get_unique("#{CONFIG.DOVETAIL_HOST}/#{path}?noImp")
        redirect.status.must_equal 302
        redirect.headers['x-not-impressed'].must_equal 'yes'
        redirect.headers['location'].must_include "/prod_#{name}/"

        # digests SHOULD exist in prod, assuming (1) it's an older episode and
        # (2) both environments are using the same SECRET_KEY
        path = "/+/prod_#{name}/" + redirect.headers['location'].split("/prod_#{name}/").last
        NEW_THREADS[name] = Thread.new do
          NEW_DOWNLOADS[name] = Excon.get(CONFIG.DOVETAIL_HOST + path)
          File.open(tmp_file(name, 'new.mp3'), 'wb') {|f| f.write(NEW_DOWNLOADS[name].body) }
        end
        PROD_THREADS[name] = Thread.new do
          PROD_DOWNLOADS[name] = Excon.get(CONFIG.DOVETAIL_PROD_HOST + path.gsub('/prod_', '/'))
          File.open(tmp_file(name, 'old.mp3'), 'wb') {|f| f.write(PROD_DOWNLOADS[name].body) }
        end
      end
    end
  end

  EPISODES.each do |name, path|

    describe name do

      it 'matches the production mp3' do
        NEW_THREADS[name].join
        PROD_THREADS[name].join
        new_stitch, old_stitch = [NEW_DOWNLOADS[name], PROD_DOWNLOADS[name]]

        new_stitch.status.must_equal 200
        new_stitch.headers['content-disposition'].must_equal 'attachment'
        new_stitch.headers['content-type'].must_equal 'audio/mpeg'
        if old_stitch.status != 200
          warn "Got #{old_stitch.status} from http://#{old_stitch.host}#{old_stitch.path}"
          old_stitch.status.must_equal 200
        end
        old_stitch.headers['content-disposition'].must_equal 'attachment'
        old_stitch.headers['content-type'].must_equal 'audio/mpeg'

        new_file = tmp_file(name, 'new.mp3')
        old_file = tmp_file(name, 'old.mp3')

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
