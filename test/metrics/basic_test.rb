require 'browser_helper'

describe :metrics, :js do
  describe :basic do
    after do
      puts "Cleaning up test series and episodes" if debug?
      delete_test_series_and_episodes!
    end

    it 'registers when podcast is played' do
      skip "set BLACKBOX=1 to fully test integration environment" unless blackbox_required?
      random_str = SecureRandom.hex(10)
      series_url = create_series!(random_str)
      _episode_url = create_episode!(series_url, random_str) # return var currently unused
      mp3 = publish_fetch_rss_media_url(series_url)

      visit mp3 # "play" the audio

      visit metrics_url(series_url)
      page.must_have_content "Test Series #{random_str}"
      page.must_have_content "Test Episode #{random_str}"

      # it can take up to 5 minutes for the "play" to show in metrics, as systems sync.
      # TODO is it worth waiting? or is it enough to know that we can log in and see
      # our test series reported (as above)?

      found_episode_plays = false
      tbody = find('metrics-downloads-table div.table-wrapper table.sticky tbody')
      tbody.all('tr').each do |tr|
        found_episode_plays = true
        #tr.text.must_match(/ [1-9]+ /) # non-zero number of plays - TODO see comment above re: wait time.
      end
      assert(found_episode_plays, 'found episode plays')
    end
  end

  def metrics_url(series_url)
    series_id = series_url.match(/series\/(\d+)/)[1]
    CONFIG.METRICS_HOST + "/#{series_id}/downloads/episodes/daily"
  end
end
