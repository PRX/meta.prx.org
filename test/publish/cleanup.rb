require 'browser_helper'

describe :publish, :js do
  describe :cleanup do
    it 'deletes test assets' do
      delete_test_series_and_episodes!
    end
  end
end
