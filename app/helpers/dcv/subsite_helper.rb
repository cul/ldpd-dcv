module Dcv::SubsiteHelper

  DEFAULT_SUBSITE_LAYOUT = 'gallery'
  DEFAULT_SUBSITE_KEY = 'catalog'

  def default_subsite_style
    "#{DEFAULT_SUBSITE_LAYOUT}-#{Dcv::Sites::Constants.default_palette}"
  end
  def subsite_key
    return controller.respond_to?(:subsite_key) ? controller.subsite_key : DEFAULT_SUBSITE_KEY
  end

  def subsite_layout
    return controller.respond_to?(:subsite_layout) ? controller.subsite_layout : DEFAULT_SUBSITE_LAYOUT
  end

  def subsite_styles
    return controller.respond_to?(:subsite_styles) ? controller.subsite_styles : default_subsite_style
  end

  def subsite_has_scope_constraints?
    @subsite.scope_filters.present?
  end

  def link_to_nav(nav_link, link_class: "nav-link", site_slug: nil)
    link_url = nav_link.link
    if nav_link.external
      if Addressable::URI.parse(nav_link.link).absolute?
        if nav_link.icon_class.present?
          return link_to(nav_link.link, target: "_blank", rel: "noopener noreferrer", class: link_class, title: nav_link.label) do
            "<i class=\"fa #{nav_link.icon_class}\" aria-hidden=\"true\"></i><i class=\"fa fa-external-link\" aria-hidden=\"true\"></i>".html_safe
          end
        else
          return link_to(nav_link.link, target: "_blank", rel: "noopener noreferrer", class: link_class) do
            "#{nav_link.label} <i class=\"fa fa-external-link\" aria-hidden=\"true\"></i>".html_safe
          end
        end
      end
    else
      site_slug ||= controller.load_subsite.slug
      link_params = {site_slug: site_slug}
      if nav_link.link.include?('#')
        nav_link.link.split('#').tap { |segs| link_params.merge!(slug: segs[0], anchor: segs[1]) }
      else
        link_params[:slug] = nav_link.link
      end
      link_url = site_page_path(link_params)
    end
    return link_to(nav_link.label, link_url, class: link_class) unless nav_link.icon_class.present?
    link_to(link_url, class: link_class, title: nav_link.label) do
      "<i class=\"fa #{nav_link.icon_class}\" aria-hidden=\"true\"></i>".html_safe
    end
  end

  def link_to_site_browse(internal_label, external_label, html_options = {})
    if subsite_has_scope_constraints?
      link_to(internal_label.html_safe, search_action_url(search_field: (controller.blacklight_config.search_fields.inject(:all_text_teim) {|m, key_val| key_val[1].default ? key_val[0] : m })), html_options)
    else
      link_to(external_label.html_safe, @subsite.persistent_url, {target: '_new'}.merge(html_options))
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
      "#{s_key} #{s_layout}".strip
    end
  end

  # if the search action URL has a query string, parse it into params
  # to allow Blacklight search form to link them as hidden fields
  def search_action_params
    Rack::Utils.parse_query URI(search_action_url).query
  end

  def subsite_search_mode
    cookie_name = "#{subsite_key}_search_mode".to_sym
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

  def search_mode_button(mode=:grid, classes: [])
    classes = 'btn result-type-button ' + classes.join(' ')
    classes << ((mode == subsite_search_mode) ? ' btn-success' : ' btn-outline-secondary')
    icon_classes = (mode == :list) ? 'fa fa-th-list' : 'fa fa-th'
    content_tag(:button, type: 'button', class: classes, :"data-toggle" => "tooltip", "aria-label": "#{mode} view", title: "#{mode} view", id: "#{mode}-mode") do
      content_tag(:i, nil, class: icon_classes)
    end
  end

  def search_placeholder_text
    if query_has_constraints?
      t(:"dlc.search_placeholder.modified.#{controller.controller_name}", default: :'dlc.search_placeholder.modifed.default').html_safe
    else
      if @subsite && @subsite.slug != controller.controller_path
        if subsite_has_scope_constraints?
          t(:"dlc.search_placeholder.new.#{@subsite.slug}", default: :'dlc.search_placeholder.new.subsite', title: @subsite.title).html_safe
        else
          t(:"dlc.search_placeholder.new.default").html_safe
        end
      else
        t(:"dlc.search_placeholder.new.#{controller.controller_name}", default: :'dlc.search_placeholder.new.default').html_safe
      end
    end
  end
end
