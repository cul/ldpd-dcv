module Dcv::Sites::SearchableController
  def default_search_mode
    subsite_config.fetch('default_search_mode',:grid)
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
end