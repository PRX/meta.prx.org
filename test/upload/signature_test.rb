require 'test_helper'

describe 'upload-signature' do
  let(:connection) do
    Excon.new("#{CONFIG.UPLOAD_HOST}/signature")
  end

  it 'returns 400 with nothing to sign' do
    resp = connection.get(query: {to_sign: ''})
    resp.status.must_equal 400
  end

  it 'return plain text media type' do
    resp = connection.get(query: {to_sign: 'hello'})
    resp.headers['Content-Type'].must_equal 'text/plain'
  end

  it 'return correct signature' do
    resp = connection.get(query: {to_sign: 'test'})
    ['TQ4Pdv8H2M69WKd4KE9APWD2Jz0=', 'g7YyJaLnX8ipwPnbGvVcKOsXf/8='].must_include(resp.body.to_s)
  end

#  it 'enables CORS' do
#    resp = connection.options
#    resp.wont_be_nil
#    resp.headers['Access-Control-Allow-Methods'].must_include 'GET'
#    resp.headers['Access-Control-Allow-Methods'].must_include 'OPTIONS'
#    resp.headers['Access-Control-Allow-Origin'].must_equal '*'
#  end
end
