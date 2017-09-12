# frozen_string_literal: true

require 'rails_helper'
require 'support/interactions'

module FeedItems
  RSpec.describe CreateOrUpdate do
    include_context 'interactions'
    it_behaves_like 'an interaction'

    let(:feed) { create(:feed) }
    let(:feed_retrieval) { create(:feed_retrieval, feed: feed) }
    let(:feed_item) { feed.feed_items.first }
    let(:url) { 'https://www.example.com' }

    let(:raw_item) do
      instance_double(
        FeedAbstract::Item::Atom,
        author: 'Example Author',
        categories: [],
        content: 'Example Content',
        contributor: 'Example Contributor',
        guid: '0000',
        link: url,
        published: 1.day.ago,
        rights: '',
        summary: 'Example Summary',
        title: 'Example Title',
        updated: 1.day.ago
      )
    end

    let(:inputs) do
      {
        feed: feed,
        item: raw_item,
        feed_retrieval: feed_retrieval
      }
    end

    describe 'the interaction' do
      context 'for an item with an existing URL' do
        let(:url) { feed_item.url }

        it 'updates the existing FeedItem record' do
          expect(result.id).to eq(feed_item.id)
        end

        it 'updates the title of the existing feed item' do
          expect(result.title).to eq(raw_item.title)
        end

        it 'updates the description of the existing feed item' do
          expect(result.description).to eq(raw_item.summary)
        end

        it 'does not change the guid of the existing feed item' do
          expect(result.guid).not_to eq(raw_item.guid)
        end
      end

      context 'for an item with a new URL' do
        let(:url) { 'https://www2.example.com' }

        it 'creates a new FeedItem record' do
          expect(result.id).not_to eq(feed_item.id)
        end

        it 'sets the guid for the feed item' do
          expect(result.guid).to eq(raw_item.guid)
        end

        it 'sets last_updated for the feed item' do
          expect(result.last_updated).to eq(raw_item.updated)
        end
      end

      it 'associates the feed retrieval with the feed item' do
        expect(result.feed_retrievals).to include(feed_retrieval)
      end

      it 'associates the feed with the feed item' do
        expect(result.feeds).to include(feed)
      end
    end
  end
end
