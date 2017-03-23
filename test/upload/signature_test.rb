require 'test_helper'

 describe 'upload-signature' do
   it 'returns 400 with nothing to sign' do
     resp = Excon.get(CONFIG.UPLOAD_HOST)
     resp.status.must_equal 400
   end

   it 'return plain text media type' do
     connection = Excon.new(CONFIG.UPLOAD_HOST)
     resp = connection.get(query: {to_sign: 'hello'})
     resp.headers['content-type'].must_equal 'text/plain'
   end

   it 'return to correct signature' do
     connection = Excon.new(CONFIG.UPLOAD_HOST)
     resp = connection.get(query: {to_sign: 'test'})
     resp.body.to_s.must_equal "TyhhPs0RA37JFn+0oWNdm25HgBc="
   end

   it 'enables CORS' do
     resp = Excon.options(CONFIG.UPLOAD_HOST)
     resp.status.wont_equal 403
   end
 end
