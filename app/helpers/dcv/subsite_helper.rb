module Dcv::SubsiteHelper

  DEFAULT_SUBSITE_LAYOUT = 'dcv'
  DEFAULT_SUBSITE_KEY = 'catalog'

  def subsite_key
    return controller.respond_to?(:subsite_key) ? controller.subsite_key : DEFAULT_SUBSITE_KEY
  end

  def subsite_layout
    return controller.respond_to?(:subsite_layout) ? controller.subsite_layout : DEFAULT_SUBSITE_LAYOUT
  end

  def subsite_styles
    return controller.respond_to?(:subsite_styles) ? controller.subsite_styles : DEFAULT_SUBSITE_LAYOUT
  end

  def subsite_map_search
    controller.subsite_config['map_search']
  end

  def link_to_nav(nav_link)
    if nav_link.external
      link_to(nav_link.link, target: "_blank", rel: "noopener noreferrer") do
        "#{nav_link.label} <sup class=\"glyphicon glyphicon-new-window\" aria-hidden=\"true\"></sup>".html_safe
      end
    else
      site_slug = controller.subsite_config[:slug]
      link_to(nav_link.label, site_page_path(site_slug: site_slug, slug: nav_link.link))
    end
  end

  def subsite_alert_message
    if controller.respond_to?(:subsite_config)
      return controller.subsite_config['alert_message'].present? ? controller.subsite_config['alert_message'] : ''
    else
      return SUBSITES['public'][DEFAULT_SUBSITE_KEY]['alert_message'].present? ? SUBSITES['public'][DEFAULT_SUBSITE_KEY]['alert_message'] : ''
    end
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

  # if the search action URL has a query string, parse it into params
  # to allow Blacklight search form to link them as hidden fields
  def search_action_params
    Rack::Utils.parse_query URI(search_action_url).query
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
    content_tag(:button, type: 'button', class: classes, :"data-toggle" => "tooltip", title: "#{mode} view", id: "#{mode}-mode") do
      content_tag(:i, nil, class: icon_classes)
    end
  end

  def search_placeholder_text
    if query_has_constraints?
      t(:"dlc.search_placeholder.modified.#{controller.controller_name}", default: :'dlc.search_placeholder.modifed.default').html_safe
    else
      if @subsite && @subsite.slug != controller.controller_path
        t(:"dlc.search_placeholder.new.#{@subsite.slug}", default: :'dlc.search_placeholder.new.subsite', title: @subsite.title).html_safe
      else
        t(:"dlc.search_placeholder.new.#{controller.controller_name}", default: :'dlc.search_placeholder.new.default').html_safe
      end
    end
  end
end
