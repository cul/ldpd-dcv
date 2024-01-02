# frozen_string_literal: true

module Dcv::Badges
  class ReadingRoom < ViewComponent::Base
    def initialize(reading_room:, current_location_uris:, **args)
      super
      @reading_room_label = (reading_room[:label] || 'These').sub(/^The /, '')
      @in_room = reading_room[:location_uri] && current_location_uris.include?(reading_room[:location_uri])
    end

    def icon_class
      @in_room ? 'fa-landmark' : 'fa-road-lock'
    end

    def badge_label
      @in_room ? 'Access materials from ' : 'Search materials available at '
    end

    def tooltip
      @in_room ? "#{@reading_room_label} materials are available onsite at your location." : "Visit the #{@reading_room_label} for onsite access to these materials."
    end

    def call
      content_tag(:span, class: [:fa, 'fa-fw', 'mr-2', icon_class], data: { toggle: 'tooltip', placement: 'top'}, title: tooltip, aria: {label: tooltip}) do
        content_tag :span, badge_label, class: 'sr-only'
      end
    end
  end
end
