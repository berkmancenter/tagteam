module Tagteam
  class Importer
    class Delicious < Importer

      class NotValidFormat < Exception
      end

      # We have to set the Nokogiri::XML::ParseOptions::HUGE option because the quirky delicious export format
      # doesn't close tags and nokogiri deep nests them.
      def parse_items
        
        doc = Nokogiri::HTML(self.filehandle) do |c|
          c.options = Nokogiri::XML::ParseOptions::HUGE
        end
        output = []
        doc.css('a').each do|i|
          item_val = {}
          item_val[:title] = i.text
          item_val[:url] = i[:href]
          item_val[:guid] = i[:href]
          item_val[:authors] = nil
          item_val[:contributors] = nil
          item_val[:description] = nil
          item_val[:content] = nil
          item_val[:rights] = nil
          # to_datetime is a rails-specific extension to the Time class.
          item_val[:date_published] = Time.at(i[:add_date].to_i).to_datetime
          item_val[:last_updated] = Time.at(i[:add_date].to_i).to_datetime
          item_val[:tag_list] = i[:tags].split(',')
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
