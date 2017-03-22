require 'test_helper'
require 'capybara/minitest'
require 'capybara/poltergeist'
require 'capybara_minitest_spec'
require 'fileutils'

SCREENSHOT_DIR = "#{File.dirname(__FILE__)}/tmp"
FileUtils.rm_rf(SCREENSHOT_DIR)

Capybara.configure do |config|
  config.run_server = false
  config.default_driver = :rack_test
end

# Capybara.register_driver :chrome do |app|
#   Capybara::Selenium::Driver.new(app, browser: :chrome)
# end

Capybara.register_driver :poltergeist do |app|
  # TODO: Intl raising some js errors
  Capybara::Poltergeist::Driver.new(app, js_errors: false)
end

class BrowserTestCase < Minitest::Spec
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  register_spec_type(self) do |desc, meta|
    meta == :js || meta[:js] unless meta.nil?
  end

  def setup
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

  # TODO: phantomjs not rendering the iframe, so need to manually navigate
  # to ID to get the session cookie
  PRX_SESSION = {}
  def publish_login!
    if PRX_SESSION[:name]
      page.driver.set_cookie(PRX_SESSION[:name], PRX_SESSION[:value], PRX_SESSION[:options])
    else
      visit CONFIG.PUBLISH_HOST + '/login'
      visit find('iframe')[:src]
      fill_in('Enter your email address', with: CONFIG.PUBLISH_USER)
      fill_in('password', with: CONFIG.PUBLISH_PASS)
      click_button('Sign In')
      cookie = page.driver.cookies.find {|c| c.first.match(/^_prx_session/)}.last
      PRX_SESSION[:name] = cookie.name
      PRX_SESSION[:value] = cookie.value
      PRX_SESSION[:options] = {domain: cookie.domain, path: cookie.path}
    end
  end
end
