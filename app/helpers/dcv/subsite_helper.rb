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

end
