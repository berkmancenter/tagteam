module Tagteam
  class Importer
    class Connotea < Importer

      class NotValidFormat < Exception
      end

      def parse_items
        # Here's where we flip through the records to import them.

      end

      def verify_format
        # Here's where we'll verify the format.
        raise NotValidFormat

      end

    end
  end
end
