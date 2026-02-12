module Dlc::MultisiteBehavior
  extend ActiveSupport::Concern
  # If you'd like to handle errors returned by Solr in a certain way,
  # you can use Rails rescue_from with a method you define in this controller,
  # uncomment:
  #
  # rescue_from Blacklight::Exceptions::InvalidRequest, with: :my_handling_method




  # overwrites Blacklight::Controller#blacklight_config
  # def blacklight_config
  #   if current_site
  #     site_specific_blacklight_config
  #   else
  #     default_catalog_controller.blacklight_config
  #   end
  # end

  # def search_state
  #   if current_site
  #     @search_state ||= Spotlight::SearchState.new(super, current_site)
  #   else
  #     super
  #   end
  # end

  # def set_locale
  #   I18n.locale = params[:locale] || I18n.default_locale
  # end

  # # This method ensures all generated URL helpers (like articles_path)
  # # automatically include the current locale in the URL
  # def default_url_options(options = {})
  #   { locale: I18n.locale }.merge options
  # end
end
