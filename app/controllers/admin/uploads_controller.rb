module Admin
  class UploadsController < ActionController::Base
    layout 'admin'
    before_action :authenticate_user!
    before_action :authorize_import

    # GET /admin/import
    def new
    end

    # POST /admin/upload
    def create
      begin
        uploaded_zip = params[:upload]
        return if uploaded_zip.nil?
        import = SubsiteImportService.new(uploaded_zip, current_user.admin?)
        import.import_subsite
        flash[:success] = "#{import.finish_message} Your upload is complete and the site changes have been saved. If content is not available, please ensure the hyacinth publish target is correctly configured for your targeted DLC environment."
      rescue Exception => err
        flash[:error] = "An error occurred: #{err.message}"
      end
      redirect_to admin_import_path
    end

    private

    def authorize_import
      authorize_action_and_scope Ability::IMPORT_SUBSITE, Site
    end
  end
end