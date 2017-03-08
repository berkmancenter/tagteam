require 'tempfile'

class ExportImportController < ApplicationController
  before_action :authenticate_user!

  def index
    breadcrumbs.add 'Export/import', export_import_path
  end

  def download
    data = Tagteam::ExportImport.get_all_user_data current_user

    send_data data, filename: format('tagteam_export_%s.json', Time.now)
  end

  def import
    if params[:file].nil?
      flash[:error] = 'File is missing, please try again.'
    else
      temp_file = Tempfile.new('tagteam_import')
      temp_file.write(File.read(params[:file].tempfile))
      ObjectSpace.undefine_finalizer(temp_file)

      Sidekiq::Client.enqueue(ImportUserData, temp_file.path)

      flash[:notice] = 'Import is in progress. You will get an email notification when the import is done.'
    end

    redirect_to request.referer
  end
end
