# frozen_string_literal: true
Sunspot.session = Sunspot::Rails::StubSessionProxy.new(Sunspot.session)
