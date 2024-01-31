module Dcv::Catalog::DateRangeSelectorBehavior
  extend ActiveSupport::Concern

  YEAR_REGEX = /(-?\d\d\d\d)/
  YEAR_SPLIT_REGEX = /(-?\d\d\d\d)-(-?\d\d\d\d)/
  DATE_RANGE_FIELD_NAME = 'lib_date_year_range_si'
  DATE_RANGE_MAX_SEGMENTS = 50
  FACET_COUNTS = 'facet_counts'
  FACET_FIELDS = 'facet_fields'
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

    year_range_facet_values = []
    date_range_field_values = year_range_response.dig(FACET_COUNTS, FACET_FIELDS, DATE_RANGE_FIELD_NAME)

    unless date_range_field_values.present?
      @date_year_segment_data = nil
      return
    end

    first_range = date_range_field_values[0]

    earliest_start_year = nil
    latest_end_year = nil

    (0...date_range_field_values.length/2).each do |facet_ix|
      year_split_match = date_range_field_values[facet_ix * 2].match(YEAR_SPLIT_REGEX)
      start_year = year_split_match.captures[0].to_i
      end_year = year_split_match.captures[1].to_i
      earliest_start_year = start_year if !earliest_start_year || start_year < earliest_start_year
      latest_end_year = end_year if !latest_end_year || end_year > latest_end_year

      year_range_facet_values << { start_year: start_year, end_year: end_year, count: date_range_field_values[1 + (facet_ix * 2)] }
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
    range_size = end_of_range - start_of_range + 1

    if range_size < 20
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
      val[:start_year] = start_of_range if val[:start_year] < start_of_range
      val[:end_year] = end_of_range if val[:end_year] > end_of_range
      start_seg = ((val[:start_year] - start_of_range) / segment_size).round(0)
      end_seg = ((val[:end_year] - start_of_range) / segment_size).round(0)
      end_seg = (segments.length - 1) if end_seg >= segments.length
      while start_seg <= end_seg
        segments[start_seg][:count] += val[:count]
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
