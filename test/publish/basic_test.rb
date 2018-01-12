require 'browser_helper'

describe :publish, :js do
  describe :basic do
    it 'gets redirected to the login page' do
      visit CONFIG.PUBLISH_HOST
      page.must_have_content "You must login"
    end

    it 'can login' do
      publish_login!
      visit CONFIG.PUBLISH_HOST
      page.must_have_content 'Home'
      page.must_have_content 'Your Series'
      page.must_have_content 'Your Standalone Episodes'
    end
  end

  describe :audio do
    after do
      puts "Cleaning up test series and episodes" if debug?
      delete_test_series_and_episodes!
    end

    it 'creates new episode with RSS feed' do
      skip "set BLACKBOX=1 to fully test integration environment" unless ENV['BLACKBOX']
      random_str = SecureRandom.hex(10)
      series_url = create_series!(random_str)
      series_url.must_match(/\/series\/\d+/)
      episode_url = create_episode!(series_url, random_str)
      episode_url.must_match(/\/story\/\d+/)
      mp3 = publish_fetch_rss_media_url(series_url)
      assert(mp3.match(/\.mp3$/), 'Found mp3 url')
    end
  end
end
