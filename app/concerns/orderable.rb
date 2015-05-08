module Orderable
  extend ActiveSupport::Concern

  def renew
    touch
  end
end
