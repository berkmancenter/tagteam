# frozen_string_literal: true

require 'rails_helper'

module Feeds
  RSpec.describe ProcessVisitorsJob, type: :job do
    subject(:job) { described_class.perform_later }

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class)
        .on_queue('subscribers')
    end
  end
end
