# frozen_string_literal: true
require 'rails_helper'

RSpec.describe UrlsStripper do
  describe '#remove_trackers_hashs_from_url' do
    it 'properly strips urls' do
      url = 'http://sotesty.com'
      stripped_url = UrlsStripper.remove_trackers_hashs_from_url(url)
      expect(stripped_url).to eq('http://sotesty.com')

      url = 'http://sotesty.com/#parampampam=123'
      stripped_url = UrlsStripper.remove_trackers_hashs_from_url(url)
      expect(stripped_url).to eq('http://sotesty.com/')

      url = 'http://sotesty.com/?utm_source=google&utm_medium=cpc&utm_term=someterm&utm_campaign=thebest#parampampam=123'
      stripped_url = UrlsStripper.remove_trackers_hashs_from_url(url)
      expect(stripped_url).to eq('http://sotesty.com/')

      url = 'http://sotesty.com/somesubpage/otherpage/?utm_source=google&utm_medium=cpc&utm_term=someterm&utm_campaign=thebest#parampampam=123'
      stripped_url = UrlsStripper.remove_trackers_hashs_from_url(url)
      expect(stripped_url).to eq('http://sotesty.com/somesubpage/otherpage/')

      url = 'http://sotesty.com/?utm_source=google&utm_medium=cpc&legalparam=legalvalue&utm_term=someterm&utm_campaign=thebest#parampampam=123'
      stripped_url = UrlsStripper.remove_trackers_hashs_from_url(url)
      expect(stripped_url).to eq('http://sotesty.com/?legalparam=legalvalue')

      url = 'http://sotesty.com?legalparam=legalvalue#parampampam=123'
      stripped_url = UrlsStripper.remove_trackers_hashs_from_url(url)
      expect(stripped_url).to eq('http://sotesty.com?legalparam=legalvalue')
    end
  end
end
