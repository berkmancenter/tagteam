require 'rss'
module Feed
  class Abstract

    def self.parse(xml = nil, opts = {:do_validate => false})
      input = (xml.respond_to?(:read)) ? xml.read : xml
      feed = RSS::Parser.parse(input,opts[:do_validate])
    end

  end
end
