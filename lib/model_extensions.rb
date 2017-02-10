# frozen_string_literal: true
module ModelExtensions
  def self.included(model)
    model.class_eval do
      include ActionView::Helpers::SanitizeHelper

      def auto_sanitize_html(*columns_to_sanitize)
        columns_to_sanitize.each do |col|
          unless send(col.to_s).nil?
            send("#{col}=", Sanitize.clean(send(col.to_s).to_str, elements: Tagteam::Application.config.html_tags_to_allow, attributes: Tagteam::Application.config.attributes_to_allow, protocols: Tagteam::Application.config.allowed_protocols))
          end
        end
      end

      # Instance methods go here.
      def auto_strip_tags(*columns_to_strip)
        columns_to_strip.each do |col|
          unless send(col.to_s).nil?
            send("#{col}=", strip_tags(send(col.to_s).to_str))
          end
        end
      end

      def auto_truncate_columns(*columns_to_truncate)
        # logger.warn('auto truncating these columns: ' + columns_to_truncate.inspect)
        columns_to_truncate.each do |col|
          unless send(col.to_s).nil?
            column_def = self.class.columns.reject { |coldef| coldef.name != col.to_s }.first
            send("#{col}=", send(col.to_s).to_str[0, column_def.limit])
          end
        end
      end
    end

    model.instance_eval do
      # Class methods go here.
      # Validate text and string column lengths automatically, and for existence.
      break unless table_exists?
      to_validate = columns.reject { |col| ![:string, :text].include?(col.type) }
      valid_output = ''
      to_validate.each do |val_col|
        #        logger.warn("Auto validating: #{val_col.name}")
        unless val_col.null
          #          logger.warn("Auto validating: #{val_col.name} for presence")
          valid_output += "validates_presence_of :#{val_col.name}\n"
        end
        if val_col.limit
          valid_output += "validates_length_of :#{val_col.name}, :maximum => #{val_col.limit}, :allow_blank => #{val_col.null}\n"
        end
      end

      before_create_content = ''
      columns.each do |col|
        next if col.default.blank?
        next unless [Integer, String, DateTime].include?(col.default.class)
        val = ''
        val = if col.default.class == Integer
                col.default
              else
                %("#{col.default}")
                end
        before_create_content += %(if self.#{col.name}.blank?
self.#{col.name} = #{val}
        end
        )
      end

      unless before_create_content.blank?
        valid_output += "before_validation do
#{before_create_content}
end"
      end
      #      logger.warn('Autovalidations:' + valid_output)

      model.class_eval valid_output

      #      This is a class method.
      #      def yuppers
      #        'yup'
      #      end
    end
  end
end
