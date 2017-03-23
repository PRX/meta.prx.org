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

    def publish_visit(url)
      publish_login!
      visit url
      publish_wait
    end

  end
end
