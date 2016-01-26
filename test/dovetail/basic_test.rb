require 'test_helper'

describe 'dovetail-basic' do

  it 'gets the root path' do
    resp = HTTP.get(DOVETAIL_HOST)
    resp.status.must_equal 404
    resp.headers['content-type'].must_equal 'text/plain'
    resp.body.to_s.must_equal "Can't help you, mate."
  end

  it 'heads the root path' do
    resp = HTTP.head(DOVETAIL_HOST)
    resp.status.must_equal 404
    resp.headers['content-type'].must_equal 'text/plain'
    resp.body.to_s.must_be_empty
  end

end
