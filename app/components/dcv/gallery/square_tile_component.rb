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
      ['square', "col-#{@default_size}"] + @additional_classes + @breakpoint_sizes.map { |bp, size| "col-#{bp}-#{size}" }
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
      view_context.thumbnail_url(@document, size: size)
    end
    def link_classes
      classes = %W{align-self-end w-100 stretched-link}
      case @hide_caption
      when :default
        classes << "text-transparent"
      else
        classes << "text-#{@hide_caption}-transparent" if @hide_caption
      end
      classes
    end
  end
end