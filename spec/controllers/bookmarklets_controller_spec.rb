require 'spec_helper'

describe BookmarkletsController do

  describe "GET 'add_item'" do
    it "returns http success" do
      get 'add_item'
      response.should be_success
    end
  end

end
