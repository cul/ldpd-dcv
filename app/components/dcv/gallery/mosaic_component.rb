# frozen_string_literal: true

module Dcv::Gallery
  class MosaicComponent < ViewComponent::Base
    def initialize(page:, num_tiles: 11, **args)
      @page = page
      @num_tiles = num_tiles
    end

    def render?
      featured_items.present?
    end

    def featured_items
      @featured_items ||= begin
        fi = controller.featured_items(rows: @num_tiles)
        if fi.length > 0
          # if there are any tiles, pad the list out with repeats to the requested number
          while (fi.length < @num_tiles) do
            fi.concat fi[0...[fi.length, @num_tiles - fi.length].min]
          end
        end
        fi
      rescue Exception => e
        Rails.logger.warn("Featured items query on #{controller} raised #{e.message}")
        []
      end
    end
  end
end