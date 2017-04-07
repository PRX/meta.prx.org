require 'test_helper'

describe 'dovetail-redirect' do
  include Dovetail::DSL

  describe 'feeder' do

    FEEDER_GUID = '23166e58-e181-4c03-b52d-6f6746a1bced'
    FEEDER_EPISODE = "#{CONFIG.DOVETAIL_HOST}/test_feeder/#{FEEDER_GUID}/my_filename.mp3"
    FEEDER_MATCHER = /\/test_feeder\/[^\/]+\/my_filename\.mp3$/

    it 'redirects a feeder episode' do
      resp = get_unique(FEEDER_EPISODE)
      resp.status.must_equal 302
      resp.headers['cache-control'].must_equal 'private, max-age=600'
      resp.headers['content-length'].to_i.must_equal 0
      resp.headers['x-not-impressed'].must_be_nil
      resp.headers['x-impressions'].to_i.must_equal 1
      resp.headers['x-repressions'].to_i.must_equal 0
      resp.headers['location'].must_match FEEDER_MATCHER
      resp.body.to_s.must_be_empty
    end

    it 'represses duplicate requests' do
      same_user_agent = unique_agent
      resp1 = Excon.get(FEEDER_EPISODE, same_user_agent)
      resp2 = Excon.get(FEEDER_EPISODE, same_user_agent)
      resp1.status.must_equal 302
      resp1.headers['x-not-impressed'].must_be_nil
      resp1.headers['x-impressions'].to_i.must_equal 1
      resp1.headers['x-repressions'].to_i.must_equal 0
      resp2.status.must_equal 302
      resp2.headers['x-not-impressed'].must_be_nil
      resp2.headers['x-impressions'].to_i.must_equal 0
      resp2.headers['x-repressions'].to_i.must_equal 1
      resp1.headers['location'].must_equal resp2.headers['location']
    end

    it 'represses head requests' do
      resp = head_unique(FEEDER_EPISODE)
      resp.status.must_equal 302
      resp.headers['cache-control'].must_equal 'private, max-age=600'
      resp.headers['x-not-impressed'].must_be_nil
      resp.headers['x-impressions'].to_i.must_equal 0
      resp.headers['x-repressions'].to_i.must_equal 1
      resp.headers['location'].must_match FEEDER_MATCHER
    end

    it 'respects the noImp parameter' do
      resp = get_unique("#{FEEDER_EPISODE}?noImp")
      resp.status.must_equal 302
      resp.headers['x-not-impressed'].must_equal 'yes'
      resp.headers['x-impressions'].to_i.must_equal 1
      resp.headers['x-repressions'].to_i.must_equal 0
    end

  end

  describe 'nonfeeder' do

    REMOTE_EPISODE = "#{CONFIG.DOVETAIL_HOST}/test_audio_remote"
    REMOTE_GUID = 'b5b5777c-ebbf-43e5-b914-22c4dcc394be'

    it 'redirects a raw mp3 file' do
      resp = get_unique("#{REMOTE_EPISODE}/#{REMOTE_GUID}/noise.mp3")
      resp.status.must_equal 302
      resp.headers['cache-control'].must_equal 'private, max-age=600'
      resp.headers['content-length'].to_i.must_equal 0
      resp.headers['x-not-impressed'].must_be_nil
      resp.headers['x-impressions'].to_i.must_equal 2
      resp.headers['x-repressions'].to_i.must_equal 0
      resp.headers['location'].must_match(/\/test_audio_remote\/[^\/]+\/noise\.mp3$/)
      resp.body.to_s.must_be_empty
    end

    it 'does not actually check if the file exists yet' do
      resp = get_unique("#{REMOTE_EPISODE}/does-not-exist/foobar.mp3")
      resp.status.must_equal 302
      resp.headers['x-impressions'].to_i.must_equal 2
      resp.headers['x-repressions'].to_i.must_equal 0
      resp.headers['location'].must_match(/test_audio_remote\/[^\/]+\/foobar\.mp3$/)
    end

  end

end
