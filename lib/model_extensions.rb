module ModelExtensions

  def self.included(model)

    model.class_eval do
      include ActionView::Helpers::SanitizeHelper

      def auto_sanitize_html(*columns_to_sanitize)
        columns_to_sanitize.each do|col|
          tags_to_allow = %w(ul li ol p b em strong div span blockquote img a dd dt dl table tr td th tbody thead tfoot i code strike abbr address h1 h2 h3 h4 h5 q s tt sub sup pre)
          attributes_to_allow = %w(href src alt title width height border cellpadding cellspacing)
          self.send("#{col}=", sanitize(self.send("#{col}").to_str, :tags => tags_to_allow, :attributes => attributes_to_allow) )
        end
      end

      # Instance methods go here.
      def auto_strip_tags(*columns_to_strip)
        columns_to_strip.each do|col|
          self.send("#{col}=", strip_tags(self.send("#{col}").to_str))
        end
      end

      def auto_truncate_columns(*columns_to_truncate)
        # logger.warn('auto truncating these columns: ' + columns_to_truncate.inspect)
        columns_to_truncate.each do|col|
          column_def = self.class.columns.reject{|coldef| coldef.name != col.to_s}.first
          self.send("#{col}=", self.send("#{col}").to_str[0,column_def.limit])
        end
      end
    end

    model.instance_eval do
      #Class methods go here.
      # Validate text and string column lengths automatically, and for existence.
      to_validate = self.columns.reject{|col| ! [:string,:text].include?(col.type)}
      valid_output = ''
      to_validate.each do|val_col|
#        logger.warn("Auto validating: #{val_col.name}")
        if ! val_col.null
#          logger.warn("Auto validating: #{val_col.name} for presence")
          valid_output += "validates_presence_of :#{val_col.name}\n"
        end
        valid_output += "validates_length_of :#{val_col.name}, :maximum => #{val_col.limit}, :allow_blank => #{val_col.null}\n"
      end

      before_create_content = ''
      self.columns.each do|col|
        unless col.default.blank?
          if [Fixnum,String,DateTime].include?(col.default.class)
            val = ''
            if col.default.class == Fixnum
              val = col.default
            else
              val = %Q|"#{col.default}"|
            end
            before_create_content += %Q|if self.#{col.name}.blank?
  self.#{col.name} = #{val}
end
|
          end
        end
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
