module Publish
  module DSL

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
      publish_login!
      series_list_url = CONFIG.PUBLISH_HOST + '/search;tab=series;perPage=50'
      visit series_list_url
      begin
        find('button', text: /^View All \d+/, wait: 30) # wait for page to laod
      rescue
        puts "Less than 50 series to clean up" if debug?
      end
      series_links = {}
      page.all('a', text: /^Test Series \w{20}$/).each do |link|
        series_url = link[:href]
        next if series_links[series_url]
        series_links[series_url] = true
      end
      series_links.keys.each do |series_url|
        puts "Cleaning up #{series_url}" if debug?
        delete_all_episodes_in_series!(series_url)
        puts "All episodes deleted" if debug?
        visit series_url
        click_button('Delete')
        click_button('Okay')
      end
      visit series_list_url
    end

    def delete_all_episodes_in_series!(series_url)
      episode_list_url = series_url + '/list'
      visit episode_list_url
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
      episode_links.keys.each do |episode_url|
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
      end
      sleep(1) # time to finish XHR
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
      visit CONFIG.PUBLISH_HOST
      click_link 'New Series'
      fill_in 'Series Title', with: "Test Series #{random_str}"
      fill_in 'Teaser', with: "Test Series Teaser #{random_str}"
      click_button 'Create'
      publish_wait_for_success
      publish_wait_for_title
      page.must_have_content("Test Series #{random_str}")
      page.must_have_content('Podcast Info')

      publish_wait_for_episodes_link
      page.must_have_content("0 Episodes in Series")

      click_link 'Podcast Info'
      click_button 'Create Podcast'
      # TODO how to select dropdown checkbox?
      # find #category.dropdown-toggle, click, then select
      current_url
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
      visit series_url
      click_link '0 Episodes in Series' # TODO better way to trigger create link?

      # TODO why doesn't click_link work here? fetching the href attribute and visit() does...
      new_ep_href = find('a', text: 'Create a new episode.')[:href]
      #click_link 'Create a new episode.'

      visit new_ep_href

      current_url.must_match(/\/story\/new\/\d+/)
      page.must_have_content 'Create Episode'
      publish_wait_for_title

      fill_in 'Title', with: "Test Episode #{random_str}"
      fill_in 'Teaser', with: "Test Episode Teaser #{random_str}"

      set_upload_input_file('.uploads input', TEST_MP3)

      publish_wait_for_save_on_upload
      click_button 'Save'
      publish_wait_for_success

      publish_wait_for_title
      page.must_have_content("Test Episode #{random_str}")

      publish_wait_for_publish_button
      find_button('Publish').trigger('click') # avoid modal overlay masking ability to click_button

      publish_wait
      # waiting for the text 'Complete' or 'Status: Published' does not seem to work..
      find_button('Edit')

      current_url
    end

    def debug?
      ENV['DEBUG'] == '1'
    end
  end
end
