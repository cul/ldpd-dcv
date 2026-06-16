# frozen_string_literal: true

module Admin
  # The admin uploads controller allows one to import a zipped subsite created by the export service
  class UploadsController < ApplicationController
    layout 'admin'
    before_action :authenticate_user!
    before_action :authorize_view, only: [:new]
    before_action :load_subsite, only: [:create]
    before_action :authorize_import, only: [:create]
    rescue_from Dcv::Exceptions::SubsiteCreateUnauthorized, with: :handle_unauthorized_create

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

    def handle_unauthorized_create
      flash[:error] = "You are not authorized to create this subsite in this environment!."
      render :new, status: :unprocessable_entity
    end

    def authorize_view
      authorize_action_and_scope Ability::VIEW_IMPORT_FORM, Site
    end

    def load_subsite
      @subsite ||= Site.find_by(slug: params[:slug])
    end

    def authorize_import
      if @subsite.nil?
        raise Dcv::Exceptions::SubsiteCreateUnauthorized unless can? Ability::IMPORT_NEW_SUBSITE, Site
      else
        raise Dcv::Exceptions::SubsiteCreateUnauthorized unless can? Ability::IMPORT_SUBSITE, @subsite
      end
    end
  end
end
