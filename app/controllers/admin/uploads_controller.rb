module Admin
  class UploadsController < ActionController::Base
    layout 'admin'

    # GET /admin/import
    def new
    end

    # POST /admin/upload
    def create
      begin
        uploaded_zip = params[:upload]
        return if uploaded_zip.nil?
        Rails.logger.debug 'upload#create'
        SubsiteImportService.new(uploaded_zip).import_subsite
        Rails.logger.debug 'upload#create returning'
        flash[:success] = "Your upload is complete and the site changes have been saved."
      rescue Exception => err
        flash[:error] = "An error occurred: #{err.message}"
      end
      redirect_to admin_import_path
    end

  end
end