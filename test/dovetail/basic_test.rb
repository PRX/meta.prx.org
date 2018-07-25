require 'test_helper'

describe 'dovetail-basic' do

  it 'gets the root path' do
    resp = Excon.get(CONFIG.DOVETAIL_HOST)
    resp.status.must_equal 404
    resp.headers['content-type'].must_equal 'text/plain'
    resp.body.to_s.must_equal "Can't help you, mate."
  end

  it 'gets the root path' do
    resp = Excon.get("#{CONFIG.DOVETAIL_HOST}/ping")
    resp.status.must_equal 200
    resp.body.to_s.must_equal "pong"
  end

  it 'is a healthy environment' do
    resp = Excon.get("#{CONFIG.DOVETAIL_HOST}/health?strict")
    resp.status.must_equal 200
    resp.headers['content-type'].must_equal 'application/json'
    JSON.parse(resp.body)['ffmpeg'].must_equal 'ok' # spot check
  end

end
