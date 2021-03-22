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
     resp.body.to_s.must_equal "1IlgT4ChsccMAJzmqW+fyYY8L3c="
   end

   it 'enables CORS' do
     resp = connection.options
     resp.wont_be_nil
     resp.headers['Access-Control-Allow-Methods'].must_include 'GET'
     resp.headers['Access-Control-Allow-Methods'].must_include 'OPTIONS'
     resp.headers['Access-Control-Allow-Origin'].must_equal '*'
   end
 end
