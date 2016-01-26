require 'test_helper'

describe 'dovetail-redirect' do

  describe 'serial' do

    it 'redirects an episode' do
      resp = HTTP.get("#{DOVETAIL_HOST}/serial/b10f2326-b3b9-478e-a74d-22c460946316/serial-s02-e05.mp3?noImp")
      resp.status.must_equal 302
      resp.headers['cache-control'].must_equal 'private, max-age=600'
      resp.headers['content-length'].to_i.must_equal 0
      resp.body.to_s.must_be_empty

      resp.headers['x-not-impressed'].must_equal 'yes'
      resp.headers['x-impressions'].to_i.must_be :>, 0
      resp.headers['x-impressions'].to_i.must_be :<, 6
      assert_includes ['0', resp.headers['x-impressions']], resp.headers['x-depressions']
    end

  end

end
