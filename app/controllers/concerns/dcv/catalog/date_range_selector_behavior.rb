module Dcv::Catalog::DateRangeSelectorBehavior
  extend ActiveSupport::Concern

  BUCKETS = 'buckets'
  DATE_RANGE_MAX_SEGMENTS = 50
  FACET_COUNTS = 'facet_counts'
  FACET_FIELDS = 'facet_fields'
  FACETS = 'facets'
  INFINITY_NEG = -1.0/0.0
  INFINITY_POS = 1.0/0.0
  KEY_DATE_YEAR_UNBOUNDED = Dcv::Solr::DocumentAdapter::ModsXml::Fields::KEY_DATE_YEAR_UNBOUNDED
  MINUS = '-'
  VAL = 'val'
  YEAR_REGEX = /^-?[0-9u]{4}--?[0-9u]{4}$/

  ## TODO: Use this to get the earliest and latest dates for the date range slider
  ## Also make sure that earliest year and latest year are stored fields.
  ## Right now, they're only indexed.
  #def get_earliest_and_latest_dates_in_entire_solr_index()
  #
  #  rsolr = RSolr.connect :url => YAML.load_file('config/blacklight.yml', aliases: true)[Rails.env]['url']
  #
  #  # Earliest date
  #  response = rsolr.get 'select', :params => {
  #    :q  => '*:*',
  #    :qt => 'search',
  #    #:fl => 'lib_start_date_year_ssi', # Only one field
  #    :rows => 1,
  #    :sort => 'lib_start_date_year_ssi asc',
  #    :facet => false,
  #  }
  #  response['response']['docs'][0].inspect
  #
  #  # Latest date
  #  response = rsolr.get 'select', :params => {
  #    :q  => '*:*',
  #    :qt => 'search',
  #    #:fl => 'lib_start_date_year_ssi', # Only one field
  #    :rows => 1,
  #    :sort => 'lib_end_date_year_ssi desc',
  #    :facet => false,
  #  }
  #  response['response']['docs'][0].inspect
  #
  #end

  def date_range_enabled?
    subsite_config.dig('date_search_configuration', 'enabled')
  end

  # This is all related to date range graph generation
  def counts_by_year_ranges_from_facet_data(date_range_field_values, start_range:, end_range:)
    earliest_end_year = end_range || INFINITY_POS
    earliest_start_year = start_range || INFINITY_POS
    latest_end_year = end_range || INFINITY_NEG
    latest_start_year = start_range || INFINITY_NEG
    errors = {}
    year_range_facet_values = (0...date_range_field_values.length/2).map do |facet_ix|
      string_val = date_range_field_values[facet_ix * 2]
      count = date_range_field_values[1 + (facet_ix * 2)]
      unless YEAR_REGEX === string_val
        errors[:format] ||= {ex: string_val, count: 0 }
        errors[:format][:count] += 1
        next
      end
      case string_val.length
      when 9
        start_year = string_val.byteslice(0,4).to_i unless string_val.start_with?(KEY_DATE_YEAR_UNBOUNDED)
        end_year = string_val.byteslice(5,4).to_i unless string_val.end_with?(KEY_DATE_YEAR_UNBOUNDED)
      when 11
        start_year = string_val.byteslice(0,5).to_i unless string_val.start_with?(KEY_DATE_YEAR_UNBOUNDED)
        end_year = string_val.byteslice(6,5).to_i unless string_val.end_with?(KEY_DATE_YEAR_UNBOUNDED)
      else
        if string_val.start_with? MINUS
          start_year = string_val.byteslice(0,5).to_i unless string_val.start_with?(KEY_DATE_YEAR_UNBOUNDED)
          end_year = string_val.byteslice(6,4).to_i unless string_val.end_with?(KEY_DATE_YEAR_UNBOUNDED)
        else
          # if only one date is BCE, it must be first or order is incorrect
          errors[:value] ||= {ex: string_val, count: 0 }
          errors[:value][:count] += 1
          next
        end
      end
      if end_year && start_year && end_year < start_year
        errors[:value] ||= {ex: string_val, count: 0 }
        errors[:value][:count] += 1
        next
      end
      if start_range.blank?
        earliest_start_year = start_year if start_year&.< earliest_start_year
        earliest_end_year = end_year if end_year&.< earliest_end_year
      end
      if end_range.blank?
        latest_end_year = end_year if end_year&.> latest_end_year
        latest_start_year = start_year if start_year&.> latest_start_year
      end
      [start_year, end_year, count]
    end
    errors.each do |error_entry|
      Rails.logger.error("#{error_entry[1][:count]} bad #{error_entry[0]}s for #{SearchBuilder::DATE_RANGE_FIELD_NAME} in search results: e.g '#{error_entry[1][:ex]}'")
    end
    earliest_end_year = nil if earliest_end_year.infinite?
    earliest_start_year = nil if earliest_start_year.infinite?
    latest_end_year = nil if latest_end_year.infinite?
    latest_start_year = nil if latest_start_year.infinite?
    [year_range_facet_values, earliest_start_year || earliest_end_year, latest_end_year || latest_start_year]
  end

  def get_date_year_segment_data_for_query()
    year_range_response = {}

    year_range_response = search_service.search_results do |builder|
      builder.processor_chain << :add_date_range_json_facets
      builder
    end.first

    date_range_field_values = year_range_response.dig(FACET_COUNTS, FACET_FIELDS, SearchBuilder::DATE_RANGE_FIELD_NAME)
    # these end points are given by json facets, with a different structure than the 'plain' facets
    earliest_start_year = year_range_response.dig(FACETS, SearchBuilder::DATE_START_FIELD_NAME, BUCKETS, 0, VAL)
    latest_end_year = year_range_response.dig(FACETS, SearchBuilder::DATE_END_FIELD_NAME, BUCKETS, 0, VAL)

    unless date_range_field_values.present?
      @date_year_segment_data = nil
      return
    end

    first_range = date_range_field_values[0]

    # If possible, use start_year and end_year to set the start_of_range and end_of_range values
    earliest_start_year = controller.params[:start_year].to_i if controller.params[:start_year].present?
    latest_end_year = controller.params[:end_year].to_i if controller.params[:end_year].present?

    year_range_facet_values, start_of_range, end_of_range =
      counts_by_year_ranges_from_facet_data(date_range_field_values, start_range: earliest_start_year, end_range: latest_end_year)


    unless year_range_facet_values.present?
      @date_year_segment_data = nil
      return
    end

    unless start_of_range.present? && end_of_range.present?
      @date_year_segment_data = nil
      return
    end

    # Generate segments
    range_size = (end_of_range - start_of_range) + 1

    if range_size < 1
      controller.flash.now[:error] = "bad values for date range bounds: start_of_range = #{start_of_range} end_of_range = #{end_of_range}"
      @date_year_segment_data = nil
      return
    elsif range_size < 20
      number_of_segments = range_size
    elsif range_size < 100
      number_of_segments = 40
    else
      number_of_segments = 30
    end

    segments = []
    highest_segment_count_value = 0

    segment_size = range_size.to_f/number_of_segments.to_f

    segments = Array.new(number_of_segments)
    i = 0
    while i < number_of_segments do
      start_of_segment_range = start_of_range+i*segment_size
      end_of_segment_range = start_of_segment_range + segment_size
      segments[i] = {
        start: start_of_segment_range.floor,
        end: end_of_segment_range.floor,
        count: 0
      }
      i += 1
    end

    year_range_facet_values.each do |val|
      next unless val
      start_year, end_year, count = val
      start_year = start_of_range if start_year.nil? || start_of_range > start_year
      end_year = end_of_range if end_year.nil? || end_of_range < end_year
      start_seg = ((start_year - start_of_range) / segment_size).round(0)
      end_seg = ((end_year - start_of_range) / segment_size).round(0)
      end_seg = (segments.length - 1) if end_seg >= segments.length
      while start_seg <= end_seg
        segments[start_seg][:count] += count
        start_seg += 1
      end
    end

    highest_segment_count_value = segments.reduce(0) { |max, new_segment| (new_segment[:count] > max) ? new_segment[:count] : max }

    @date_year_segment_data = {
      start_of_range: start_of_range,
      end_of_range: end_of_range,
      earliest_start_year: earliest_start_year,
      latest_end_year: latest_end_year,
      highest_segment_count_value: highest_segment_count_value,
      number_of_segments: number_of_segments,
      years_per_segment: segment_size,
      segments: segments
    }

  end

end
