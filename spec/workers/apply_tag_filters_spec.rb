require 'rails_helper'

describe ApplyTagFilters do
  context 'multiple filters exist' do
    include_context 'user owns a hub with a feed and items'
    before(:each) do
      @tag_a = create(:tag, name: 'a')
      @filter_a = create(:add_tag_filter, hub: @hub, tag: @tag_a, scope: @hub)
      @tag_b = create(:tag, name: 'b')
      @filter_b = create(:add_tag_filter, hub: @hub, tag: @tag_b, scope: @hub)
      @tag_c = create(:tag, name: 'c')
      @filter_c = create(:add_tag_filter, hub: @hub, tag: @tag_c,
                         scope: @feed_items.first)
      @filters = [@filter_a, @filter_b, @filter_c]
    end

    describe 'receiving a single filter' do
      context 'filters prior to given filter are unapplied' do
        it 'applies all unapplied filters and then applies the given filter' do
          ApplyTagFilters.perform_async(@filter_c.id)
          @filters.each(&:reload)
          expect(@filters.map(&:applied)).to all( be_truthy )
        end
        it 'does not apply filters newer than given filter' do
          ApplyTagFilters.perform_async(@filter_b.id)
          expect(@filter_c.applied).to be_falsey
        end
      end

      context 'filter deleted before worker performs' do
        it 'does not throw an error' do
          @filter_c.destroy
          expect{ApplyTagFilters.perform_async(@filter_c.id)}.not_to raise_error
        end
      end

      describe 'receiving zero items' do
        it "applies to all items in given filter's scope" do
          ApplyTagFilters.perform_async(@filter_a.id)
          tag_lists = tag_lists_for(@hub.feed_items, @hub.tagging_key)
          expect(tag_lists).to show_effects_of @filter_a
        end
      end

      describe 'receiving one item' do
        before(:each) do
          @selected_item = @feed_items.order(:id).first
        end

        it 'applies the given filter to the given item' do
          ApplyTagFilters.perform_async(@filter_a.id, @selected_item.id)
          tag_lists = tag_lists_for(@selected_item, @hub.tagging_key)
          expect(tag_lists).to show_effects_of @filter_a
        end

        it 'does not apply the given filter to other items' do
          ApplyTagFilters.perform_async(@filter_a.id, @selected_item.id)
          without_selected = @feed_items.all - [@selected_item]
          tag_lists = tag_lists_for(without_selected, @hub.tagging_key)
          expect(tag_lists).to not_show_effects_of @filter_a
        end
      end

      describe 'receiving multiple items' do
        before(:each) do
          @selected_items = @feed_items.order(:id).all.take(4)
        end

        it 'applies the given filter to all given items' do
          ApplyTagFilters.perform_async(@filter_a.id, @selected_items.map(&:id))
          tag_lists = tag_lists_for(@selected_items, @hub.tagging_key)
          expect(tag_lists).to show_effects_of @filter_a
        end

        it 'does not apply to given filter to other items' do
          ApplyTagFilters.perform_async(@filter_a.id, @selected_items.map(&:id))
          without_selected = @feed_items.all - @selected_items
          tag_lists = tag_lists_for(without_selected, @hub.tagging_key)
          expect(tag_lists).to not_show_effects_of @filter_a
        end
      end
    end

    describe 'receiving multiple filters' do
      describe 'receiving unapplied filters out of order' do
        it 'applies them all in order' do
          ApplyTagFilters.perform_async(@filters.reverse.map(&:id))
          @filters.each(&:reload)
          expect(@filters.map(&:applied)).to all( be_truthy )
        end
      end
    end
  end
end
