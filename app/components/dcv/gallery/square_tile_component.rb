# frozen_string_literal: true

module Dcv::Gallery
  class SquareTileComponent < ViewComponent::Base
    def initialize(document:, image_size:, default:, downscale: true, **args)
      @document = document
      @image_size = image_size
      @default_size = default
      @downscale = downscale
      @breakpoint_sizes = args.slice(:sm, :md, :lg)
      @hide_caption = args.fetch(:hide_caption, false)
      @additional_classes = args.fetch(:additional_classes, [])
    end
    def tile_classes
      ['square', 'card', "col-#{@default_size}"] + @additional_classes + @breakpoint_sizes.map { |bp, size| "col-#{bp}-#{size}" }
    end
    def caption
      @document.title
    end
    def labelled_by
      @labelled_by ||= @document.id.gsub(/[^a-zA-Z0-9]/,'') + "-label"
    end
    def item_url
      @document.persistent_url
    end
    def image_url(size = @image_size)
      helpers.thumbnail_url(@document, size: size)
    end
    def link_classes
      classes = %W{card-img-overlay d-flex align-items-end justify-content-end caption}
      case @hide_caption
      when :default
        classes << "text-transparent"
      when :sm
        classes << "text-md-down-transparent"
      else
        classes << "text-#{@hide_caption}-down-transparent" if @hide_caption
      end
      classes
    end
    def tooltip_class
      return "tooltip" if @hide_caption == :default
      return "tooltip-md-none" if @hide_caption == :sm
      "tooltip-none"
    end
  end
end