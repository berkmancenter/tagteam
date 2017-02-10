# frozen_string_literal: true
module Tagteam
  class ImportFileNotThere < RuntimeError
  end

  class Importer
    attr_reader :filehandle, :target_object, :file_type

    def initialize(file_name = nil, opts = {})
      options = {
        target_object: nil,
        file_type: 'Connotea'
      }.merge(opts)

      @file_type = options[:file_type]
      @target_object = options[:target_object]

      begin
        @filehandle = file_name.respond_to?(:read) ? file_name : File.open(file_name)
      rescue Exception
        raise Tagteam::ImportFileNotThere
      end
    end

    def import
      parse_items.each do |i|
      end
    end
  end
end
