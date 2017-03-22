require 'minitest/reporters'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'excon'
require 'json'
require 'config'

begin require 'pry' rescue LoadError end

# output format
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
