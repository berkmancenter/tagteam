require 'rails_helper'

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
      should respond_to(:owners)
      should validate_presence_of(:title)
      should ensure_length_of(:title).is_at_most(500.bytes)
      should ensure_length_of(:description).is_at_most(2.kilobytes)
      should have_db_index(:title)
      should have_db_index(:tag_prefix)
    end
  end

end
