module Dcv::Catalog::DateRangeSelectorBehavior
  extend ActiveSupport::Concern

  included do
    before_filter :get_date_year_segment_data_for_query, :only => [:index]
  end

  # This is all related to date range graph generation

  def get_date_year_segment_data_for_query()

    max_number_of_segments = 50
    date_range_field_name = 'lib_date_year_range_si'

    year_range_response = get_facet_field_response(date_range_field_name, params, {'facet.limit' => '1000000'})
    year_range_facet_values = []

    year_split_regex = /(-?\d\d\d\d)-(-?\d\d\d\d)/

    if year_range_response['facet_counts']['facet_fields'][date_range_field_name].length == 0
      @date_year_segment_data = nil
      return
    end

    first_range = year_range_response['facet_counts']['facet_fields'][date_range_field_name][0]

    # Initialize earliest_year and latest_year based on first result
    year_split_match = first_range.match(year_split_regex)
    earliest_start_year = year_split_match.captures[0].to_i
    latest_end_year = year_split_match.captures[1].to_i

    year_range_response['facet_counts']['facet_fields'][date_range_field_name].each_slice(2){|facet_and_count|
      year_split_match = facet_and_count[0].match(year_split_regex)
      start_year = year_split_match.captures[0].to_i
      end_year = year_split_match.captures[1].to_i
      earliest_start_year = start_year if start_year < earliest_start_year
      latest_end_year = end_year if end_year > latest_end_year

      year_range_facet_values << {:start_year => start_year, :end_year => end_year, :count => facet_and_count[1]}
    }

    # Generate segments
    if latest_end_year == earliest_start_year
      number_of_segments = 1
      segment_size = 1
    else

      if (latest_end_year - earliest_start_year) < max_number_of_segments
         number_of_segments = (latest_end_year - earliest_start_year)
         segment_size = 1
      else
        number_of_segments = max_number_of_segments
        segment_size = ((latest_end_year - earliest_start_year)/number_of_segments.to_f).ceil
        number_of_segments = ((latest_end_year - earliest_start_year)/segment_size).ceil+1
      end
    end

    segments = []
    highest_segment_count_value = 0

    number_of_segments.times {|i|
      start_of_segment_range = earliest_start_year+i*segment_size
      end_of_segment_range = start_of_segment_range + segment_size
      new_segment = {}
      new_segment[:start] = start_of_segment_range
      new_segment[:end] = end_of_segment_range
      new_segment[:count] = 0

      year_range_facet_values.each {|val|
        start_year = val[:start_year]
        end_year = val[:start_year]
        if (start_year >= start_of_segment_range && start_year <= end_of_segment_range) || (end_year >= start_of_segment_range && end_year <= end_of_segment_range)
          new_segment[:count] += val[:count]
        end
      }

      highest_segment_count_value = new_segment[:count] if new_segment[:count] > highest_segment_count_value
      segments << new_segment

    }

    @date_year_segment_data = {
      earliest_start_year: earliest_start_year,
      latest_end_year: latest_end_year,
      highest_segment_count_value: highest_segment_count_value,
      years_per_segment: segment_size,
      segments: segments
    }

    #earliest_start_date_year = start_date_year_facet_values.keys[0].to_i
    #
    #end_date_year_response = get_facet_field_response('lib_end_date_year_si', params, {"facet.limit" => '1000000'})
    #end_date_year_facet_values = {}
    #end_date_year_response['facet_counts']['facet_fields']['lib_end_date_year_si'].each_slice(2){|facet_and_count|
    #  end_date_year_facet_values[facet_and_count[0]] = facet_and_count[1]
    #}
    #latest_end_date_year = end_date_year_facet_values.keys[end_date_year_facet_values.length-1].to_i
    #
    #if earliest_start_date_year.blank? && latest_end_date_year.blank?
    #  @date_year_segment_data = {
    #    'results_found' => false
    #  }
    #  return
    #end
    #
    ## If only a start date or only an end date, make earliest_start_date_year and latest_end_date_year equal for this response
    #
    #earliest_start_date_year = latest_end_date_year if earliest_start_date_year.blank?
    #latest_end_date_year = earliest_start_date_year if latest_end_date_year.blank?
    #
    #segment_size = (latest_end_date_year - earliest_start_date_year)/max_number_of_segments
    #if segment_size < 1
    #  segment_size = (latest_end_date_year - earliest_start_date_year)
    #else
    #  segment_size = max_number_of_segments
    #end
    #
    ## Generate segments
    #segments = []
    #
    #
    #@date_year_segment_data = {
    #  'results_found' => true,
    #  'minYear' => earliest_start_date_year,
    #  'maxYear' => latest_end_date_year,
    #  'segments' => segments
    #}

  end

end
