require 'browser_helper'

describe 'publish-basic', :js do

  it 'gets redirected to the login page' do
    visit CONFIG.PUBLISH_HOST
    page.must_have_content "You must login"
  end

  it 'can login' do
    publish_login!
    visit CONFIG.PUBLISH_HOST
    page.must_have_content 'Home'
    page.must_have_content 'Ryan Cavis'
    page.must_have_content 'Your Series'
  end

  it 'can view a story' do
    publish_login!
    visit "#{CONFIG.PUBLISH_HOST}/story/187086"
    page.must_have_content 'Edit Episode'
    page.must_have_content 'Episode 2e'
  end

end
