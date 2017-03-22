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

  # TODO: Intl errors prevent waiting for spinners to disappear
  # it 'can navigate to a story' do
  #   publish_visit CONFIG.PUBLISH_HOST
  #   all('publish-home-story')[1].click
  #   publish_wait
  #   page.must_have_content 'Edit Episode'
  #   page.must_have_content 'Episode Title'
  #   page.must_have_content 'Cover Image'
  # end

end
