module Dcv::Sites::ConfiguredLayouts
  def subsite_key
    subsite_config['slug']
  end

  def subsite_layout
    configured_layout = subsite_config['layout'] || 'default'
    return subsite_key if configured_layout == 'custom'
    return Dcv::Sites::Constants.default_layout if configured_layout == 'default'
    configured_layout
  end

  def subsite_palette
    palette = subsite_config['palette'] || 'default'
    (palette == 'default') ? Dcv::Sites::Constants.default_palette : palette
  end

  def subsite_styles
    return [subsite_layout] unless Dcv::Sites::Constants::PORTABLE_LAYOUTS.include?(subsite_layout)
    subsite_layout == Site::LAYOUT_REPOSITORIES ? ["#{Site::LAYOUT_GALLERY}-#{subsite_palette}"] : ["#{subsite_layout}-#{subsite_palette}"]
  end

  def signature_image_path
    path = File.join("", "images", "sites", load_subsite&.slug, "signature.svg")
    if File.exist?(File.join(Rails.root, "public", path)) 
      # Add the modification time to the end of the path URL in order to bust browser caches when a new file is uploaded
      modification_time = File.mtime(File.join(Rails.root, "public", path)).to_i
      return "#{path}?v=#{modification_time}"
    end 
    view_context.asset_path("signature/signature.svg")
  end

  def signature_banner_image_path
    path = File.join("", "images", "sites", load_subsite&.slug, "signature-banner.png")
    if File.exist?(File.join(Rails.root, "public", path)) 
      modification_time = File.mtime(File.join(Rails.root, "public", path)).to_i
      return "#{path}?v=#{modification_time}"
    end
    view_context.asset_path("signature/signature-banner.png")
  end

  # this method is stubbed here for configured sites and overridden in custom sites
  def carousel_image_paths
    []
  end
end