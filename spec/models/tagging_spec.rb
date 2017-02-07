# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ActsAsTaggableOn::Tagging, type: :model, needs_review: true do
  context 'Tagging was created by a bookmarker' do
    it 'is owned by the bookmarker'
  end

  context 'Tagging was created by an import process' do
    it 'is owned by something...'
  end

  # it_behaves_like "a tagging deactivator"
end
