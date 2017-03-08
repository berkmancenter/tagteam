# frozen_string_literal: true
class ImportUserData
  include Sidekiq::Worker
  sidekiq_options queue: :importer

  def self.display_name
    'Importing user data'
  end

  def perform(file_path, user_email)
    file_content = File.read(file_path)

    File.delete(file_path)

    Tagteam::ExportImport.import(file_content, user_email)
  end
end
