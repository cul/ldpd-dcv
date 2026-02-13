# frozen_string_literal: true

# Blacklight controller that handles searches and document requests
class CatalogController < ApplicationController
  include Blacklight::Catalog

  before_action :current_site # Invoke current_site before every action to populate the instance variable
  around_action :switch_locale
  delegate :blacklight_config, to: :current_site

  # Controller actions

  # Other methods that aren't controller actions

  def current_site_slug
    params[:site_slug] || "collections" # The 'collections' site is our main DLC site
  end

  def default_url_options
    super.merge(
      current_site_slug.present? ? { site_slug: current_site_slug } : {}
    ).merge(
      { locale: I18n.locale }
    )
  end

  def current_site
    @current_site ||= begin
      site = Site.new(current_site_slug)
      site.configure_blacklight!
      site
    end
  end

  private

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
