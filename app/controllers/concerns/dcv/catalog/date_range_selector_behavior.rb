module Dcv::Catalog::DateRangeSelectorBehavior
  extend ActiveSupport::Concern

  DATE_RANGE_FIELD_NAME = 'lib_date_year_range_si'
  DATE_RANGE_MAX_SEGMENTS = 50
  FACET_COUNTS = 'facet_counts'
  FACET_FIELDS = 'facet_fields'
  INFINITY_NEG = -1.0/0.0
  INFINITY_POS = 1.0/0.0
  MINUS = '-'
  YEAR_REGEX = /^-?\d{4}--?\d{4}$/

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
  def counts_by_year_ranges_from_facet_data(date_range_field_values)
    earliest_start_year = INFINITY_POS
    latest_end_year = INFINITY_NEG

    year_range_facet_values = (0...date_range_field_values.length/2).map do |facet_ix|
      string_val = date_range_field_values[facet_ix * 2]
      count = date_range_field_values[1 + (facet_ix * 2)]
      return [nil, nil, nil] unless YEAR_REGEX === string_val
      case string_val.length
      when 9
        start_year = string_val.byteslice(0,4).to_i
        end_year = string_val.byteslice(5,4).to_i
      when 11
        start_year = string_val.byteslice(0,5).to_i
        end_year = string_val.byteslice(6,5).to_i
      else
        if string_val.start_with? MINUS
          start_year = string_val.byteslice(0,5).to_i
          end_year = string_val.byteslice(6,4).to_i
        else
          Rails.logger.error("bad values for #{DATE_RANGE_FIELD_NAME} in search results: #{string_val}")
          return [nil, nil, nil]
          # if we allow misordered data, then...
          #  start_year = string_val.byteslice(0,4).to_i
          #  end_year = string_val.byteslice(5,5).to_i
        end
      end
      if end_year < start_year
        Rails.logger.error("bad values for #{DATE_RANGE_FIELD_NAME} in search results: #{string_val}")
        return [nil, nil, nil]
      end
      earliest_start_year = start_year if start_year < earliest_start_year
      latest_end_year = end_year if end_year > latest_end_year
      [start_year, end_year, count]
    end
    earliest_start_year = nil if earliest_start_year.infinite?
    latest_end_year = nil if latest_end_year.infinite?
    [year_range_facet_values, earliest_start_year, latest_end_year]
  end

  def get_date_year_segment_data_for_query()
    year_range_response = {}

    year_range_response = search_service.search_results do |builder|
      # merging here circumvents facet field config lookup
      builder.merge(
      'facet' => true,
      'facet.limit' => '1000000000',
      'facet.field' => DATE_RANGE_FIELD_NAME,
      'rows' => 0
      )
      builder
    end.first

    date_range_field_values = year_range_response.dig(FACET_COUNTS, FACET_FIELDS, DATE_RANGE_FIELD_NAME)

    unless date_range_field_values.present?
      @date_year_segment_data = nil
      return
    end

    first_range = date_range_field_values[0]

    year_range_facet_values, earliest_start_year, latest_end_year = counts_by_year_ranges_from_facet_data(date_range_field_values)

    unless year_range_facet_values.present?
      @date_year_segment_data = nil
      return
    end

    # If possible, use start_year and end_year to set the start_of_range and end_of_range values
    if controller.params[:start_year].present?
      start_of_range = controller.params[:start_year].to_i
    else
      start_of_range = earliest_start_year
    end

    if controller.params[:end_year].present?
      end_of_range = controller.params[:end_year].to_i
    else
      end_of_range = latest_end_year
    end

    # Generate segments
    range_size = (end_of_range - start_of_range) + 1

    if range_size < 1
      Rails.logger.error("bad values for date range bounds: start_of_range = #{start_of_range} end_of_range = #{end_of_range}")
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
      start_year, end_year, count = val
      start_year = start_of_range if start_of_range > start_year
      end_year = end_of_range if end_of_range < end_year
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
