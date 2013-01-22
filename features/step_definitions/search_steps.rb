When "I search for \"$query\"" do |query|
    visit item_search_hub_path(@hub.id,:q => query, :per_page => 500)
end

Then "there should be at least one result" do
    page.all('.feed_item').count.should be > 0
end

Then "every result should have the tag \"$tag\"" do |tag|
    page.all(:xpath, "//a[@class='tag'][text()='#{tag}']").count.should == page.all('.feed_item').count
end
