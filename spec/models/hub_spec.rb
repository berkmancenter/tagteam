# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_context'

RSpec.describe Hub, type: :model do
  let(:valid_tag_delimiters) { ['&', '^'] }
  let(:hub) { create(:hub, tags_delimiter: [valid_tag_delimiters[1]]) }

  context 'it has items' do
    include_context 'user owns a hub with a feed and items'

    context 'it has tag filters' do
      before do
        @existing_tag_a = create(:tag, name: 'a')
        @existing_tag_b = create(:tag, name: 'b')
        @add_tag = create(:tag, name: 'c')
        @change_tag = create(:tag, name: 'd')

        @feed_items.limit(4).each do |item|
          create(:tagging, tag: @existing_tag_a,
                           taggable: item, tagger: item.feeds.first)
          # This doesn't run on its own because items have already been created.
          item.copy_global_tags_to_hubs
        end

        @feed_items.reverse_order.limit(4).each do |item|
          create(:tagging, tag: @existing_tag_b,
                           taggable: item, tagger: item.feeds.first)
          # This doesn't run on its own because items have already been created.
          item.copy_global_tags_to_hubs
        end

        @add_filter = create(:add_tag_filter, hub: @hub, tag: @add_tag, scope: @hub)
        @mod_filter = create(:modify_tag_filter, hub: @hub, tag: @existing_tag_a,
                                                 new_tag: @change_tag, scope: @hub)
        @del_filter = create(:delete_tag_filter, hub: @hub,
                                                 tag: @existing_tag_b, scope: @hub)
      end

      context 'no filters have been applied' do
        describe '#last_applied_tag_filter' do
          it 'returns nil' do
            expect(@hub.last_applied_tag_filter).to be_nil
          end
        end

        describe '#apply_tag_filters_until' do
          it 'applies the first filter up to the given filter' do
            @hub.apply_tag_filters_until(@del_filter)
            applied = [@add_filter.reload.applied, @mod_filter.reload.applied]
            expect(applied).to all(be_truthy)
          end
        end
      end

      context 'all filters have been applied' do
        before do
          [@add_filter, @mod_filter, @del_filter].each(&:apply)
        end

        describe '#tag_filters_between' do
          it 'returns an exclusive list of filters' do
            filters = @hub.tag_filters_between(@add_filter, @del_filter)
            expect(filters).to match_array([@mod_filter])
          end
        end

        describe '#apply_tag_filters_after' do
          it 'applies every filter after the given filter' do
            new_filter = create(:add_tag_filter, hub: @hub, scope: @hub)
            expect(new_filter.applied).to be_falsey
            @hub.apply_tag_filters_after(@del_filter)
            new_filter.reload
            expect(new_filter.applied).to be_truthy
          end
        end

        describe '#apply_tag_filters_until' do
          it 'applies every unapplied filter up to (not including) the given filter' do
            new_filter_1 = create(:add_tag_filter, hub: @hub, scope: @hub)
            new_filter_2 = create(:add_tag_filter, hub: @hub, scope: @hub)
            expect(new_filter_1.applied).to be_falsey
            expect(new_filter_2.applied).to be_falsey
            @hub.apply_tag_filters_until(new_filter_2)
            new_filter_1.reload
            new_filter_2.reload
            expect(new_filter_1.applied).to be_truthy
            expect(new_filter_2.applied).to be_falsey
          end
        end

        describe '#last_applied_tag_filter' do
          it 'returns the most recent filter that has been applied' do
            expect(@hub.last_applied_tag_filter).to eq(@del_filter)
            new_filter_1 = create(:add_tag_filter, hub: @hub, scope: @hub)
            expect(@hub.last_applied_tag_filter).to eq(@del_filter)
            new_filter_1.apply
            expect(@hub.last_applied_tag_filter).to eq(new_filter_1)
          end
        end
      end
    end
  end

  context 'tags_delimiter' do
    describe 'validation' do
      it 'creates tags_delimiter' do
        hub.tags_delimiter << valid_tag_delimiters[0]
        hub.save

        expect(hub.tags_delimiter).to include(valid_tag_delimiters[0])
      end

      it 'does not create tags_delimiter for duplicate delimiter' do
        hub.tags_delimiter << valid_tag_delimiters[1]
        hub.save

        expect(hub.errors.keys).to include(:tags_delimiter)
      end
    end
  end
end
