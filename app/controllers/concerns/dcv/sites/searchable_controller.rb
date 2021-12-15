module Dcv::Sites::SearchableController
  extend ActiveSupport::Concern
  included do
    helper_method :search_action_path, :search_action_url
  end
  def default_search_mode
    search_config = load_subsite&.search_configuration
    search_config ? search_config.display_options.default_search_mode : :grid
  end

  def default_search_mode_cookie
    slug = load_subsite&.slug || controller_path
    cookie_name = "#{slug}_search_mode"
    cookie_name.gsub!('/','_')
    cookie_name = cookie_name.to_sym
    cookie = cookies[cookie_name]
    unless cookie
      cookies[cookie_name] = default_search_mode.to_sym
    end
  end

  def controller
    self
  end

  # shims from Blacklight 6 controller fetch to BL 7 search service
  def fetch(id = nil, extra_controller_params = {})
    return search_service.fetch(id, extra_controller_params)
  end

  def repository
    search_service.repository
  end

  def search_results(params, &block)
    search_service_class.new(config: blacklight_config, user_params: params, **search_service_context).search_results(&block)
  end
end