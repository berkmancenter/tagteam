# frozen_string_literal: true

module Orderable
  extend ActiveSupport::Concern

  def renew
    touch
  end
end
