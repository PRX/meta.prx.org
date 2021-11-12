require 'test_helper'

describe 'dovetail-basic' do

  it 'gets the root path' do
    resp = Excon.get(CONFIG.DOVETAIL_HOST)
    resp.status.must_equal 200
    resp.headers['content-type'].must_include 'text/plain'
    resp.body.to_s.must_equal "Dovetail. You know, for podcasts."
  end

end
