require 'test_helper'

describe 'dovetail-redirect' do

  def http_unique
    HTTP.headers('user-agent' => "meta.prx.org tests #{SecureRandom.uuid}")
  end

  describe 'feeder' do

    FEEDER_GUID = '23166e58-e181-4c03-b52d-6f6746a1bced'
    FEEDER_EPISODE = "#{DOVETAIL_HOST}/test_feeder/#{FEEDER_GUID}/my_filename.mp3"
    FEEDER_MATCHER = /\/test_feeder\/[^\/]+\/my_filename\.mp3$/

    it 'redirects a feeder episode' do
      resp = http_unique.get(FEEDER_EPISODE)
      resp.status.must_equal 302
      resp.headers['cache-control'].must_equal 'private, max-age=600'
      resp.headers['content-length'].to_i.must_equal 0
      resp.headers['x-not-impressed'].must_be_nil
      resp.headers['x-impressions'].to_i.must_equal 1
      resp.headers['x-depressions'].to_i.must_equal 0
      resp.headers['location'].must_match FEEDER_MATCHER
      resp.body.to_s.must_be_empty
    end

    it 'depresses duplicate requests' do
      same_user_agent = http_unique
      resp1 = same_user_agent.get(FEEDER_EPISODE)
      resp2 = same_user_agent.get(FEEDER_EPISODE)
      resp1.status.must_equal 302
      resp1.headers['x-not-impressed'].must_be_nil
      resp1.headers['x-impressions'].to_i.must_equal 1
      resp1.headers['x-depressions'].to_i.must_equal 0
      resp2.status.must_equal 302
      resp2.headers['x-not-impressed'].must_be_nil
      resp2.headers['x-impressions'].to_i.must_equal 1
      resp2.headers['x-depressions'].to_i.must_equal 1
      resp1.headers['location'].must_equal resp2.headers['location']
    end

    it 'depresses head requests' do
      resp = http_unique.head(FEEDER_EPISODE)
      resp.status.must_equal 302
      resp.headers['cache-control'].must_equal 'private, max-age=600'
      resp.headers['x-not-impressed'].must_be_nil
      resp.headers['x-impressions'].to_i.must_equal 1
      resp.headers['x-depressions'].to_i.must_equal 1
      resp.headers['location'].must_match FEEDER_MATCHER
    end

    it 'respects the noImp parameter' do
      resp = http_unique.get("#{FEEDER_EPISODE}?noImp")
      resp.status.must_equal 302
      resp.headers['x-not-impressed'].must_equal 'yes'
      resp.headers['x-impressions'].to_i.must_equal 1
      resp.headers['x-depressions'].to_i.must_equal 0
    end

  end

  describe 'nonfeeder' do

    REMOTE_EPISODE = "#{DOVETAIL_HOST}/test_audio_remote"
    REMOTE_GUID = 'b5b5777c-ebbf-43e5-b914-22c4dcc394be'

    it 'redirects a raw mp3 file' do
      resp = http_unique.get("#{REMOTE_EPISODE}/#{REMOTE_GUID}/noise.mp3")
      resp.status.must_equal 302
      resp.headers['cache-control'].must_equal 'private, max-age=600'
      resp.headers['content-length'].to_i.must_equal 0
      resp.headers['x-not-impressed'].must_be_nil
      resp.headers['x-impressions'].to_i.must_equal 2
      resp.headers['x-depressions'].to_i.must_equal 0
      resp.headers['location'].must_match /\/test_audio_remote\/[^\/]+\/noise\.mp3$/
      resp.body.to_s.must_be_empty
    end

    it 'does not actually check if the file exists yet' do
      resp = http_unique.get("#{REMOTE_EPISODE}/does-not-exist/foobar.mp3")
      resp.status.must_equal 302
      resp.headers['x-impressions'].to_i.must_equal 2
      resp.headers['x-depressions'].to_i.must_equal 0
      resp.headers['location'].must_match /test_audio_remote\/[^\/]+\/foobar\.mp3$/
    end

  end

end
