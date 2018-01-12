module Publish
  module DSL
    def profile_time(start, label)
      diff = Time.now - start
      puts sprintf("%s - %0.03f seconds", label, diff) if ENV['PROFILE_TIME']
      Time.now
    end

    # TODO: phantomjs not rendering the iframe, so need to manually navigate
    # to ID to get the session cookie
    PRX_SESSION = {}
    def publish_login!
      start = Time.now
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
      profile_time(start, 'publish_login')
    end

     # wait for loading spinners to disappear from page
    def publish_wait
      page.wont_have_css 'publish-spinner'
    end

    def publish_wait_for_title
      find('#title')
    end

    def publish_wait_for_episodes_link
      find('a', text: '0 Episodes in Series')
    end

    def publish_wait_for_success
      find('div.success')
    end

    def publish_visit(url)
      publish_login!
      visit url
      publish_wait
    end

    def delete_test_series_and_episodes!
      skip "set BLACKBOX=1 to fully test integration environment" unless ENV['BLACKBOX']
      publish_login!
      ttl_start = Time.now
      start = profile_time(ttl_start, 'Deleting test series and episodes - start')
      series_list_url = CONFIG.PUBLISH_HOST
      visit series_list_url
      start = profile_time(start, 'visit series list url done')
      btn = find('a', text: /^View(ing)? All [1-9]+/i) # /not/ 0
      expecting_series_count = btn.text.match(/(\d+)/)[1]
      start = profile_time(start, 'wait for View All button')
      series_links = {}
      page.assert_selector('a', text: /^Test Series \w{20}/, between: 1..expecting_series_count.to_i)
      all('a', text: /^Test Series \w{20}/, between: 1..expecting_series_count.to_i).each do |link|
        series_url = link[:href]
        next if series_links[series_url]
        series_links[series_url] = true
      end
      start = profile_time(start, 'list of series links')
      series_links.keys.each do |series_url|
        s = profile_time(start, "starting clean up of #{series_url}")
        puts "Cleaning up #{series_url}" if debug?
        delete_all_episodes_in_series!(series_url)
        puts "All episodes deleted" if debug?
        s = profile_time(s, "All episodes deleted for series #{series_url}")
        visit series_url
        s = profile_time(s, 're-visit series_url')
        click_button('Delete')
        click_button('Okay')
        profile_time(s, 'clicked Delete and Okay')
      end
      profile_time(start, 'deleted each series')
      profile_time(ttl_start, 'deleted all test series and episodes - end')
      #visit series_list_url
    end

    def delete_all_episodes_in_series!(series_url)
      start = Time.now
      episode_list_url = series_url + '/list'
      visit episode_list_url
      start = profile_time(start, 'visit episode_list_url')
      begin
        find('a', text: /Search among these episodes/)
      rescue
        return # no episodes
      end
      episode_links = {}
      page.all('a', text: /^Test Episode \w{20}$/).each do |link|
        episode_url = link[:href]
        next if episode_links[episode_url]
        episode_links[episode_url] = true
      end
      start = profile_time(start, 'got episode links from series')
      episode_links.keys.each do |episode_url|
        s = Time.now
        puts "Deleting #{episode_url}" if debug?
        m = episode_url.match(/\/story\/(\d+)$/)
        ep_id = m[1]
        # there's a wonky bug with Poltergeist and Angular where the modal Okay
        # button does not trigger a DELETE call. So we do it ourselves.
        puts "Episode ID: #{ep_id}" if debug?
        del_url = 'UNKNOWN'
        authz_token = 'UNKNOWN'
        page.driver.network_traffic.each do |req|
          if req.url.match(/authorization$/)
            del_url = req.url + "/stories/#{ep_id}"
            req.headers.each do |h|
              if h['name'] == 'Authorization'
                authz_token = h['value']
                break
              end
            end
          end
          break if authz_token != 'UNKNOWN'
        end
        puts "DELETE #{del_url}" if debug?
        page.execute_script(publish_js_to_delete_episode(del_url, authz_token))
        profile_time(s, "deleted episode #{ep_id}")
      end
      sleep(1) # time to finish XHR
      profile_time(start, 'finished deleting all episodes in series')
    end

    def publish_js_to_delete_episode(del_url, authz_token)
      debugger_line = debug? ? "console.log('DELETE ok')" : ''
      <<~JSCRIPT
        var xhr=new XMLHttpRequest();
        xhr.open('DELETE','#{del_url}');
        xhr.setRequestHeader('Authorization', '#{authz_token}');
        xhr.setRequestHeader('Accept', 'application/hal+json');
        xhr.onload=function() {
          if (xhr.status === 204) {
            #{debugger_line}
          } else {
            console.log('XHR fail:' + xhr.status)
          }
        };
        xhr.withCredentials = true;
        xhr.send();
      JSCRIPT
    end

    def create_series!(random_str = SecureRandom.hex(10))
      publish_login!
      start = Time.now
      visit CONFIG.PUBLISH_HOST
      click_link 'New Series'
      start = profile_time(start, 'Clicked New Series link')
      fill_in 'Series Title', with: "Test Series #{random_str}"
      fill_in 'Teaser', with: "Test Series Teaser #{random_str}"
      click_button 'Create'
      start = profile_time(start, 'Create series button clicked')
      publish_wait_for_success
      publish_wait_for_title
      page.must_have_content("Test Series #{random_str}")
      page.must_have_content('Podcast Info')
      start = profile_time(start, 'Series create XHR done')

      publish_wait_for_episodes_link
      page.must_have_content("0 Episodes in Series")

      click_link 'Podcast Info'
      click_button 'Create Podcast'
      find('#category .dropdown-toggle').click
      within '#category .dropdown-menu' do
        first('.dropdown-item').find('a').click
      end
      find('#explicit .dropdown-toggle').click
      within '#explicit .dropdown-menu' do
        all('.dropdown-item')[1].find('a').click
      end
      click_button 'Save'
      start = profile_time(start, 'Clicked Save on Podcast Info')
      
      # wait for Saved in order to confirm XHR
      find_button('Saved', disabled: true)

      profile_time(start, 'series created')
      current_url
    end

    def publish_podcast_feed_url(series_url)
      start = Time.now
      podcast_url = series_url.sub('/podcast', '') + '/podcast'
      visit podcast_url
      sleep(1) # give podcast XHR a moment to finish. No particular DOM el to wait on.
      feed_url_el = find("input[name='publishedUrl']")
      tries = 0
      while(feed_url_el['value'] == '') do
        #puts "feed url: #{feed_url_el['value']}"
        sleep(1)
        tries += 1
        fail "Can't find feed url" if tries > 5
      end
      profile_time(start, "fetched RSS feed URL")
      feed_url_el['value']
    end

    def publish_feeder_podcast_url(series_url)
      podcast_url = publish_podcast_feed_url(series_url)
      # the rss link on the series page is the S3 version.
      # we skip the S3 step and go right to the feeder version.
      m = podcast_url.match(/(\d+)\/feed-rss.xml$/)
      "#{CONFIG.FEEDER_HOST}/podcasts/#{m[1]}"
    end

    def publish_fetch_rss_feed(series_url)
      @_podcast_feeds ||= {}
      feed_url = @_podcast_feeds[series_url] ||= publish_feeder_podcast_url(series_url)

      # maybe it's the S3 HTTP response headers, but the poltergeist browser will
      # cache the initial RSS response and not detect when the feed has changed,
      # so we do the equivalent of a "force reload" each time.
      page.driver.browser.clear_memory_cache

      visit feed_url
      Nokogiri::XML(page.body)
    end

    def publish_fetch_rss_media_url(series_url)
      # feed is cached and takes awhile to show published episode,
      # so try for a max of N seconds to fetch it with a valid Item
      rss = publish_fetch_rss_feed(series_url)
      tries = 0
      max_tries = ENV.fetch('MAX_RSS_TRIES', 40).to_i
      while (rss.xpath('//rss/channel/item').to_s == '')
        sleep(2)
        tries += 1
        break if tries >= max_tries
        rss = publish_fetch_rss_feed(series_url)
      end
      rss.xpath('//rss/channel/item/enclosure').attr('url').value
    end

    def set_upload_input_file(selector, path)
      # can't use attach_file() because our input field is invisible
      Capybara.ignore_hidden_elements = false
      upload_input = find(selector)
      upload_input.set(path)
      Capybara.ignore_hidden_elements = true
    end

    def publish_wait_for_duration
      find('dt', text: 'Duration:')
    end

    def publish_wait_for_save_on_upload
      find_button('Save', wait: 10)
    end

    def publish_wait_for_publish_button
      find_button('Publish', wait: 30)
      find('p', text: 'Ready to publish', wait: 10)
    end

    def create_episode!(series_url, random_str = SecureRandom.hex(10))
      start = Time.now
      visit series_url
      start = profile_time(start, 'reached series_url')

      click_link '0 Episodes in Series' # TODO better way to trigger create link?

      start = profile_time(start, 'clicked link to create new episode')

      # TODO why doesn't click_link work here? fetching the href attribute and visit() does...
      new_ep_href = find('a', text: 'Create a new episode.')[:href]
      #click_link 'Create a new episode.'

      visit new_ep_href

      start = profile_time(start, 'reached New Episode page')

      current_url.must_match(/\/story\/new\/\d+/)
      page.must_have_content 'Create Episode'
      publish_wait_for_title

      fill_in 'Title', with: "Test Episode #{random_str}"
      fill_in 'Teaser', with: "Test Episode Teaser #{random_str}"

      set_upload_input_file('.uploads input', TEST_MP3)

      publish_wait_for_save_on_upload
      click_button 'Save'
      start = profile_time(start, 'Clicked Save on new Episode')
      publish_wait_for_success

      publish_wait_for_title
      page.must_have_content("Test Episode #{random_str}")

      start = profile_time(start, 'Test Episode created - waiting for publish button')

      publish_wait_for_publish_button
      find_button('Publish').trigger('click') # avoid modal overlay masking ability to click_button

      start = profile_time(start, 'Publish button clicked')

      publish_wait

      start = profile_time(start, 'Looking for Edit button to confirm published status')
      # waiting for the text 'Complete' or 'Status: Published' does not seem to work..
      find_button('Edit')

      profile_time(start, 'episode created')
      current_url
    end

    def debug?
      ENV['DEBUG'] == '1'
    end
  end
end
