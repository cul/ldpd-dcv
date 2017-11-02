module Dcv::SubsiteHelper

  DEFAULT_SUBSITE_LAYOUT = 'dcv'
  DEFAULT_SUBSITE_KEY = 'catalog'

  def subsite_key
    return controller.respond_to?(:subsite_key) ? controller.subsite_key : DEFAULT_SUBSITE_KEY
  end

  def subsite_layout
    return controller.respond_to?(:subsite_layout) ? controller.subsite_layout : DEFAULT_SUBSITE_LAYOUT
  end

  def search_result_view_override_for_current_project_facet
    return nil unless controller.respond_to?(:search_result_view_overrides)
    search_result_view_overrides = controller.search_result_view_overrides

    current_project_facet_value = params.fetch(:f, {}).fetch('lib_project_short_ssim', []).first
    if search_result_view_overrides.key?(current_project_facet_value)
      search_result_view_overrides[current_project_facet_value]
    else
      'none'
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

end
