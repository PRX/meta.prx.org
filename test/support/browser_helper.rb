require 'test_helper'
require 'capybara/minitest'
require 'capybara/poltergeist'
require 'capybara_minitest_spec'
require 'fileutils'
require 'publish_dsl'

SCREENSHOT_DIR = "#{File.dirname(__FILE__)}/../tmp"
TEST_MP3 = "#{File.dirname(__FILE__)}/test.mp3"
FileUtils.rm_rf(SCREENSHOT_DIR)

Capybara.configure do |config|
  config.run_server = false
  config.default_driver = :rack_test
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: true)
end

Capybara.default_max_wait_time = 5

class NilLogger
  def puts * ; end
end

class BrowserTestCase < Minitest::Spec
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include Publish::DSL

  register_spec_type(self) do |desc, meta|
    meta == :js || meta[:js] unless meta.nil?
  end

  def setup
    debug = ENV['DEBUG'] == '1'
    driver_options = {
      js_errors: true,
      phantomjs_logger: STDERR,
      debug: false,
      phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes', '--web-security=false'],
    }
    if debug
      driver_options[:phantomjs_options] << '--debug=true'
    end
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new app, driver_options
    end
    Capybara.current_driver = :poltergeist
  end

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  def snap!
    name = self.name.gsub(/^test_\d+_/, '').gsub(' ', '_')
    path = "#{SCREENSHOT_DIR}/#{name}"
    num = 1
    while File.exist?("#{path}_#{num}.png") do num += 1 end
    page.save_screenshot("#{path}_#{num}.png")
    File.write("#{path}_#{num}.html", body)
  end
end
