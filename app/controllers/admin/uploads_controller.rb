# frozen_string_literal: true

module Admin
  # The admin uploads controller allows one to import a zipped subsite created by the export service
  class UploadsController < ApplicationController
    layout 'admin'
    before_action :authenticate_user!
    before_action :authorize_import

    # GET /admin/import
    def new; end

    # POST /admin/upload
    def create
      begin
        uploaded_zip = params[:upload]
        import = SubsiteImportService.new(uploaded_zip, current_user.is_admin?)

        import.import_subsite
        flash[:success] =
          "#{import.finish_message} Your upload is complete and the site changes have been saved. If content is not available, please ensure the hyacinth publish target is correctly configured for your targeted DLC environment."
      rescue StandardError => e
        flash[:error] = "An error occurred: #{e.message}"
      end

      redirect_to admin_import_path
    end

    private

    def authorize_import
      authorize_action_and_scope Ability::IMPORT_SUBSITE, Site
    end
  end
end
