require 'browser_helper'

describe :metrics, :js do
  describe :basic do
    after do
      puts "Cleaning up test series and episodes" if debug?
      delete_test_series_and_episodes!
    end

    it 'registers when podcast is played' do
      random_str = SecureRandom.hex(10)
      mp3 = setup_fixtures(random_str)
      visit mp3 # "play" the audio

      visit CONFIG.METRICS_HOST
      page.must_have_content "Test Series #{random_str}"
      page.must_have_content "Test Episode #{random_str}"

      # it can take up to 5 minutes for the "play" to show in metrics, as systems sync.
      # TODO is it worth waiting? or is it enough to know that we can log in and see
      # our test series reported (as above)?

      found_episode_plays = false
      tbody = find('metrics-downloads-table div.table-wrapper table.scroll-x tbody')
      tbody.all('tr').each do |tr|
        found_episode_plays = true
        #tr.text.must_match(/ [1-9]+ /) # non-zero number of plays - TODO see comment above re: wait time.
      end
      assert(found_episode_plays, 'found episode plays')
    end

    def setup_fixtures(random_str)
      series_url = create_series!(random_str)
      create_episode!(series_url, random_str)
      publish_fetch_rss_media_url(series_url)
    end
  end
end
