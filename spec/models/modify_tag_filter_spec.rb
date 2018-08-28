# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ModifyTagFilter, type: :model do
  def new_add_filter(tag_name = 'just-a-tag')
    new_tag = create(:tag, name: tag_name)
    create(:add_tag_filter, tag: new_tag, hub: @hub, scope: @hub)
  end

  context 'the filter is scoped to a hub with some items with tag "a"' do
    include_context 'user owns a hub with a feed and items'
    before do
      @tag = create(:tag, name: 'a')
      @feed_items.order(:id).limit(4).each do |item|
        create(:tagging, tag: @tag, taggable: item, tagger: item.feeds.first)
        # This doesn't run on its own because items have already been created.
        item.copy_global_tags_to_hubs
      end
    end
    context 'the filter changes tag "a" to tag "b"' do
      before do
        @new_tag = create(:tag, name: 'b')
        @filter = create(:modify_tag_filter, hub: @hub, tag: @tag,
                                             new_tag: @new_tag, scope: @hub)
      end

      describe '#apply' do
        it 'creates taggings for tag "b"' do
          @filter.apply
          taggings = ActsAsTaggableOn::Tagging
                     .where(tag_id: @new_tag.id, context: @hub.tagging_key)
          expect(taggings.count).to be > 0
        end

        it 'deactivates all tag "a" taggings' do
          @filter.apply
          taggings = ActsAsTaggableOn::Tagging
                     .where(tag_id: @tag.id, context: @hub.tagging_key)
          expect(taggings.count).to eq(0)
        end

        it 'replaces all tag "a" taggings with tag "b" taggings' do
          @filter.apply
          tag_lists = tag_lists_for(@hub.feed_items, @hub.tagging_key)
          expect(tag_lists).to show_effects_of @filter
        end

        it 'only changes taggings on items that had tag "a"' do
          affected = @feed_items.tagged_with(@tag.name, on: @hub.tagging_key).to_a
          @filter.apply
          now_affected = @feed_items.tagged_with(@new_tag.name, on: @hub.tagging_key).to_a
          expect(affected).to match_array(now_affected)
        end

        it 'only changes taggings on items that had tag "a" even if passed them' do
          affected = @feed_items.tagged_with(@tag.name, on: @hub.tagging_key).to_a
          @filter.apply(items: @feed_items)
          now_affected = @feed_items.tagged_with(@new_tag.name, on: @hub.tagging_key).to_a
          expect(affected).to match_array(now_affected)
        end
      end

      describe '#rollback' do
        it 'deletes any owned taggings' do
          @filter.apply
          query = ActsAsTaggableOn::Tagging
                  .where(tagger_id: @filter.id, tagger_type: @filter.class.base_class.name)
          expect(query.count).to be > 0
          @filter.rollback
          expect(query.count).to eq(0)
        end

        it 'reactivates all tag "a" taggings' do
          pre_filter_taggings = @feed_items.map(&:taggings).flatten
          @filter.apply
          @filter.rollback
          post_rollback_taggings = @feed_items.map(&:taggings).flatten
          expect(pre_filter_taggings).to match_array(post_rollback_taggings)
        end
      end

      describe '#deactivates_taggings' do
        context 'a feed item exists with tag "a" and tag "b"' do
          before do
            @feed_item = create(:feed_item_from_feed, :tagged,
                                feed: @hub_feed.feed, tag: 'b',
                                tag_context: @hub.tagging_key)
            create(:tagging, taggable: @feed_item, tag: @tag,
                             context: @hub.tagging_key)
          end
          it 'returns both taggings' do
            expect(@filter.deactivates_taggings).to include(*@feed_item.taggings)
          end
        end

        context 'a feed item exists with tag "b" but not tag "a"' do
          before do
            @feed_item = create(:feed_item, :tagged, tag: 'b',
                                                     tag_context: @hub.tagging_key)
          end
          it 'does not return that tagging' do
            expect(@filter.deactivates_taggings)
              .to not_contain @feed_item.taggings.first
          end
        end
      end

      describe '#simulate' do
        it 'changes "a" to "b" in a given tag list' do
          list = %w(a c d)
          expect(@filter.simulate(list)).to match_array(%w(b c d))
        end

        it 'prevents duplicate tags' do
          list = %w(a b c d)
          expect(@filter.simulate(list)).to match_array(%w(b c d))
        end
      end

      describe '#filter_chain' do
        context 'no related filters exist' do
          it 'returns the passed filter' do
            related = @filter.filter_chain
            expect(related).to eq([@filter])
          end
        end

        context 'one newer related filter exists' do
          it 'returns the correct chain' do
            new_filter = create(:modify_tag_filter, hub: @hub,
                                                    tag: @new_tag, scope: @hub)
            related = @filter.filter_chain
            expect(related).to eq([@filter, new_filter])
          end
        end

        context 'many related filters exist and this is the oldest and first' do
          it 'returns the correct chain' do
            # a -> b, b -> c, c -> d, d -> e = a -> e
            tag_1 = create(:tag, name: 'c')
            tag_2 = create(:tag, name: 'd')
            tag_3 = create(:tag, name: 'e')
            filter_1 = create(:modify_tag_filter, hub: @hub, tag: @new_tag,
                                                  new_tag: tag_1, scope: @hub)
            filter_2 = create(:modify_tag_filter, hub: @hub, tag: tag_1,
                                                  new_tag: tag_2, scope: @hub)
            filter_3 = create(:modify_tag_filter, hub: @hub, tag: tag_2,
                                                  new_tag: tag_3, scope: @hub)
            related = @filter.filter_chain
            chain = [@filter, filter_1, filter_2, filter_3]
            expect(related).to eq(chain)
          end
        end

        context 'many related filters exist and this is oldest but last' do
          it 'returns only this because newer are not affected' do
            # a -> b, x -> y, y -> z, z -> a = a -> b
            tag_1 = create(:tag, name: 'x')
            tag_2 = create(:tag, name: 'y')
            tag_3 = create(:tag, name: 'z')
            create(:modify_tag_filter, hub: @hub, tag: tag_1,
                                       new_tag: tag_2, scope: @hub)
            create(:modify_tag_filter, hub: @hub, tag: tag_2,
                                       new_tag: tag_3, scope: @hub)
            create(:modify_tag_filter, hub: @hub, tag: tag_3,
                                       new_tag: @tag, scope: @hub)
            related = @filter.filter_chain
            chain = [@filter]
            expect(related).to eq(chain)
          end
        end

        context 'many related filters exist and this is newest and in the middle' do
          it 'returns the filter chain' do
            # y -> z, z -> a, b -> c, a -> b = y -> b
            tag_1 = create(:tag, name: 'y')
            tag_2 = create(:tag, name: 'z')
            tag_3 = create(:tag, name: 'c')
            filter_1 = create(:modify_tag_filter, hub: @hub, tag: tag_1,
                                                  new_tag: tag_2, scope: @hub)
            filter_2 = create(:modify_tag_filter, hub: @hub, tag: tag_2,
                                                  new_tag: @tag, scope: @hub)
            create(:modify_tag_filter, hub: @hub, tag: @new_tag,
                                       new_tag: tag_3, scope: @hub)
            @filter.touch
            related = @filter.filter_chain
            chain = [filter_1, filter_2, @filter]
            expect(related).to eq(chain)
          end
        end
      end

      it_behaves_like 'an existing tag filter in a populated hub'
    end
  end

  context 'the filter is scoped to a hub' do
    def add_filter(old_tag = 'just-a-tag', new_tag = 'not-just-a-tag')
      unless ActsAsTaggableOn::Tag.find_by(name: old_tag)
        create(:tag, name: old_tag)
      end

      filter = create(:modify_tag_filter,
                      tag: ActsAsTaggableOn::Tag.find_by(name: old_tag),
                      new_tag: create(:tag, name: new_tag),
                      hub: @hub, scope: @hub)
      filter
    end

    def filter_list
      @hub.tag_filters
    end

    context 'user owns a hub with a feed and items' do
      include_context 'user owns a hub with a feed and items'

      it 'modifies tags' do
        old_tag_name = 'just-a-tag'
        new_tag_name = 'not-just-a-tag'

        old_tag = create(:tag, name: old_tag_name)
        create(:tagging, tag: old_tag, taggable: @feed_items.first,
                         context: @hub.tagging_key)

        filter = add_filter(old_tag_name, new_tag_name)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key)

        expect(new_tag_lists).to show_effects_of filter
      end

      it 'modifies tags using wildcards' do
        old_tag_name = 'just-a-great-tag'
        new_tag_name = 'just-a-bad-tag'
        filter_tag_name = '*great*'
        new_filter_tag_name = '*bad*'

        old_tag = create(:tag, name: old_tag_name)
        create(:tagging, tag: old_tag, taggable: @feed_items.first,
                         context: @hub.tagging_key)

        filter = add_filter(filter_tag_name, new_filter_tag_name)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key)

        expect(new_tag_lists.first).to include(new_tag_name)

        old_tag_name = 'testy-tag'
        new_tag_name = 'no-wildcards-tag'
        filter_tag_name = 'testy*'
        new_filter_tag_name = 'no-wildcards-tag'

        old_tag = create(:tag, name: old_tag_name)
        create(:tagging, tag: old_tag, taggable: @feed_items.first,
                         context: @hub.tagging_key)

        filter = add_filter(filter_tag_name, new_filter_tag_name)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key)

        expect(new_tag_lists.first).to include(new_tag_name)

        old_tag_name = 'testy-single-wildcard-tag'
        new_tag_name = 'single-wildcard-tag'
        filter_tag_name = 'testy-*'
        new_filter_tag_name = '*'

        old_tag = create(:tag, name: old_tag_name)
        create(:tagging, tag: old_tag, taggable: @feed_items.first,
                         context: @hub.tagging_key)

        filter = add_filter(filter_tag_name, new_filter_tag_name)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key)

        expect(new_tag_lists.first).to include(new_tag_name)
      end
    end

    it_behaves_like 'a hub-level tag filter'
  end

  context 'the filter is scoped to a feed' do
    def add_filter(old_tag = 'just-a-tag', new_tag = 'not-just-a-tag')
      unless ActsAsTaggableOn::Tag.find_by(name: old_tag)
        create(:tag, name: old_tag)
      end

      create(:modify_tag_filter,
             tag: ActsAsTaggableOn::Tag.find_by(name: old_tag),
             new_tag: create(:tag, name: new_tag),
             hub: @hub, scope: @hub_feed)
    end

    def filter_list
      @hub_feed.tag_filters
    end

    def setup_other_feeds_tags(filter, hub_feed)
      filter = create(:add_tag_filter, tag: filter.tag, hub: hub_feed.hub,
                                       scope: hub_feed)
      filter.apply
    end

    context 'user owns a hub with a feed and items' do
      include_context 'user owns a hub with a feed and items'

      it 'modifies tags' do
        old_tag = 'just-a-tag'
        new_tag = 'not-just-a-tag'

        filer_old = new_add_filter(old_tag)
        filer_old.apply

        filter = add_filter(old_tag, new_tag)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_items.reload, @hub.tagging_key, true)

        expect(new_tag_lists).to show_effects_of filter
      end
    end

    it_behaves_like 'a feed-level tag filter'
  end

  context 'the filter is scoped to an item' do
    def add_filter(old_tag = 'just-a-tag', new_tag = 'not-just-a-tag')
      unless ActsAsTaggableOn::Tag.find_by(name: old_tag)
        create(:tag, name: old_tag)
      end

      create(:modify_tag_filter,
             tag: ActsAsTaggableOn::Tag.find_by(name: old_tag),
             new_tag: create(:tag, name: new_tag),
             hub: @hub, scope: @feed_item)
    end

    def filter_list
      @feed_item.tag_filters
    end

    def setup_other_items_tags(filter, item)
      filter = create(:add_tag_filter, tag: filter.tag, hub: @hub,
                                       scope: item)
      filter.apply
    end

    context 'user owns a hub with a feed and items' do
      include_context 'user owns a hub with a feed and items'

      it 'modifies tags' do
        @feed_item = @feed_items.order(:id).first
        old_tag = 'just-a-tag'
        new_tag = 'not-just-a-tag'

        filer_old = new_add_filter(old_tag)
        filer_old.apply

        filter = add_filter(old_tag, new_tag)
        filter.apply

        new_tag_lists = tag_lists_for(@feed_item, @hub.tagging_key)
        expect(new_tag_lists).to show_effects_of filter
      end
    end

    it_behaves_like 'an item-level tag filter'
  end

  it_behaves_like 'a tag filter in an empty hub', :modify_tag_filter
  it_behaves_like 'a tag filter', :modify_tag_filter
end
