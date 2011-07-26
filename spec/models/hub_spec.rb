require 'spec_helper'

describe Hub do

  before :all do
    @hub1 = Hub.create(
      :title => 'Test hub', 
      :description => 'Test description',
      :tag_prefix => ''
    )
    @hub2 = Hub.create(
      :title => 'Test hub', 
      :description => 'Test description'
    )
  end

  before :each do
    @hub = Hub.new
  end

  context do
    it 'has basic attributes', :attributes => true do
      should have_many(:hub_feeds)
      should have_many(:hub_tag_filters)
      should have_many(:republished_feeds)
      should have_many(:feeds).through(:hub_feeds)
      

    end
  end

end
