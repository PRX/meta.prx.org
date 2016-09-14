require 'minitest/reporters'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'http'
require 'json'
require 'config'

begin require 'pry' rescue LoadError end

# output format
if ENV['CI']
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
end
