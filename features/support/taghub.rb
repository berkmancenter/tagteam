Sunspot.remove_all!
system "rake tagteam:tiny_test_hubs"
# Wait for workers to catch up
sleep 60
