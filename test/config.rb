require 'http'

# dovetail connection
if ENV['DOVETAIL_HOST'].nil?
  puts 'you must set DOVETAIL_HOST'
  exit 255
end
HTTP.head(ENV['DOVETAIL_HOST'])

# hosts
DOVETAIL_HOST = ENV['DOVETAIL_HOST']
DOVETAIL_PROD = ENV['DOVETAIL_PROD']
FEEDER_HOST   = ENV['FEEDER_HOST']
