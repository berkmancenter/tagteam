system "rake tagteam:tiny_test_hubs && rake sunspot:reindex"
Sunspot.remove_all!
