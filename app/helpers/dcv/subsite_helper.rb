module Dcv::SubsiteHelper

  DEFAULT_SUBSITE_LAYOUT = 'dcv'
  DEFAULT_SUBSITE_KEY = 'dcv'

  def subsite_key
    return controller.respond_to?(:subsite_key) ? controller.subsite_key : DEFAULT_SUBSITE_KEY
  end

  def subsite_layout
    return controller.respond_to?(:subsite_layout) ? controller.subsite_layout : DEFAULT_SUBSITE_LAYOUT
  end

  def render_subsite_body_classes
    s_key = subsite_key
    s_layout = subsite_layout

    if s_key == s_layout
      return s_key
    else
      s_key + ' ' + s_layout
    end

  end

  def subsite_search_mode
    cookie_name = "#{subsite_layout}_search_mode".to_sym
    cookie = cookies[cookie_name]
    @current_search_mode ||= begin
      if cookie
        cookie.to_sym
      elsif controller.respond_to?(:default_search_mode)
        controller.default_search_mode.to_sym
      else
        :grid
      end
    end
  end

  def search_mode_button(mode=:grid)
    classes = 'btn result-type-button'
    classes << ((mode == subsite_search_mode) ? ' btn-success' : ' btn-default')
    icon_classes = (mode == :list) ? 'glyphicon glyphicon-th-list' : 'glyphicon glyphicon-th'
    content_tag(:button, type: 'button', class: classes, title: "#{mode} view", id: "#{mode}-mode") do
      content_tag(:i, nil, class: icon_classes)
    end
  end

end
