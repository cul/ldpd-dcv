module Dcv::Sites::ConfiguredLayouts
  def subsite_key
    subsite_config['slug']
  end

  def subsite_layout
    configured_layout = subsite_config['layout'] || 'default'
    configured_layout = DCV_CONFIG.fetch(:default_layout, 'portrait') if configured_layout == 'default'
    configured_layout = subsite_key if configured_layout == 'custom'
    configured_layout
  end

  def subsite_styles
    return [subsite_layout] unless Dcv::Sites::Constants::PORTABLE_LAYOUTS.include?(subsite_layout)
    palette = subsite_config['palette'] || 'default'
    palette = DCV_CONFIG.fetch(:default_palette, 'monochromeDark') if palette == 'default'
    ["#{subsite_layout}-#{palette}"]
  end
end