When "I search for \"$query\"" do |query|
    visit item_search_hub_path(@hub.id,:q => ERB::Util.url_encode(query))
end

Then "every result should have the tag \"$tag\"" do |tag|

end
