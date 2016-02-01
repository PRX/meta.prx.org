require 'minitest/reporters'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'http'
require 'json'

begin require 'pry' rescue LoadError end

# output format
if ENV['CI']
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
end

# dovetail connection
if ENV['DOVETAIL_HOST'].nil?
  puts 'you must set DOVETAIL_HOST'
  exit 255
end
HTTP.head(ENV['DOVETAIL_HOST'])

# hosts
DOVETAIL_HOST = ENV['DOVETAIL_HOST']
