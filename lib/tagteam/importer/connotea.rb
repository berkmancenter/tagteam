module Tagteam
  class Importer
    class Connotea < Importer

      class NotValidFormat < Exception
      end

      def parse_items
        doc = Nokogiri::XML(self.filehandle)
        output = []
        doc.css('Post').each do|item|
          item_val = {}
          item_val[:title] = item.css('title').text
          item_val[:tag_list] = item.xpath('dc:subject').collect{|t| t.text}
          item_val[:description] = item.css('description').text
          output << item_val
        end
        return output
      end

      def verify_format
        # Here's where we'll verify the format.
        raise NotValidFormat

      end

    end
  end
end
