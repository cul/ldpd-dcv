module Dcv::Sites::ConfiguredLayouts
  def subsite_key
    subsite_config['slug']
  end

  def subsite_layout
    configured_layout = subsite_config['layout'] || 'default'
    return subsite_key if configured_layout == 'custom'
    return DCV_CONFIG.fetch(:default_layout, 'portrait') if configured_layout == 'default'
    configured_layout
  end

  def subsite_palette
    palette = subsite_config['palette'] || 'default'
    (palette == 'default') ? DCV_CONFIG.fetch(:default_palette, 'monochromeDark') : palette
  end

  def subsite_styles
    return [subsite_layout] unless Dcv::Sites::Constants::PORTABLE_LAYOUTS.include?(subsite_layout)
    ["#{subsite_layout}-#{subsite_palette}"]
  end
end