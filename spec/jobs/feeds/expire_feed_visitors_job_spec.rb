# frozen_string_literal: true

require 'rails_helper'

module Feeds
  RSpec.describe ExpireFeedVisitorsJob, type: :job do
    subject(:job) { described_class.perform_later }

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class)
        .on_queue('subscribers')
    end

    describe 'running the job' do
      let(:job) { described_class.perform_now }

      before do
        create_pair(:feed_visitor, created_at: 8.days.ago)
        create_pair(:feed_visitor, created_at: 6.days.ago)
      end

      it 'removes feed visitors that are more than 7 days old' do
        expect { job }.to change { FeedVisitor.count }.by(-2)
      end
    end
  end
end
