class ExportImportController < ApplicationController
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
      content = File.read(params[:file].tempfile)
      result = Tagteam::ExportImport.import content

      if result
        flash[:notice] = 'Successfully imported user data.'
      else
        flash[:error] = 'File is not properly structured or empty, please try again.'
      end
    end

    redirect_to request.referer
  end
end
