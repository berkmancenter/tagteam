module Tagteam
  class Importer
    class Connotea < Importer

      class NotValidFormat < Exception
      end

      def parse_items
        rdf = FeedAbstract::Feed.new(self.filehandle)
        rdf.items
      end

      def verify_format
        # Here's where we'll verify the format.
        raise NotValidFormat

      end

    end
  end
end
