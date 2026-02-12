# frozen_string_literal: true

# Blacklight controller that handles searches and document requests
class CatalogController < ApplicationController
  include Blacklight::Catalog

  # before_action :set_locale

  delegate :blacklight_config, to: :current_site

  def current_site_slug
    params.to_unsafe_h[:site_slug]
  end

  def default_url_options
    super.merge(current_site_slug.present? ? { site_slug: current_site_slug } : {})
  end

  def current_site
    @current_site ||= begin
      site = Site.new(current_site_slug)
      site.configure_blacklight!
      site
    end
  end

  private

  # def set_locale
  #   # TODO: Code below is a placeholder.  Maybe implement for real later on.
  #   I18n.locale = params[:locale] || I18n.default_locale
  # end
end
