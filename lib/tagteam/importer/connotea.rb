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
          item_val[:url] = item.css('uri link').text
          item_val[:guid] = item[:about]
          item_val[:authors] = item.xpath('dc:creator').text
          item_val[:contributors] = nil
          item_val[:description] = item.css('description').text
          item_val[:content] = nil
          item_val[:rights] = nil
          item_val[:date_published] = DateTime.parse(item.css('created').text)
          item_val[:last_updated] = DateTime.parse(item.css('updated').text)

          item_val[:tag_list] = item.xpath('dc:subject').collect{|t| t.text}
          output << item_val
        end
        self.filehandle.rewind
        return output
      end

      def verify_format
        # Here's where we'll verify the format.
        raise NotValidFormat
      end

    end
  end
end
