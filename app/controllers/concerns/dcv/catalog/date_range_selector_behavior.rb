module Dcv::Catalog::DateRangeSelectorBehavior
  extend ActiveSupport::Concern

  included do
    before_filter :get_date_year_segment_data_for_query, :only => [:index]
  end

  ## TODO: Use this to get the earliest and latest dates for the date range slider
  ## Also make sure that earliest year and latest year are stored fields.
  ## Right now, they're only indexed.
  #def get_earliest_and_latest_dates_in_entire_solr_index()
  #
  #  rsolr = RSolr.connect :url => YAML.load_file('config/solr.yml')[Rails.env]['url']
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

  # This is all related to date range graph generation

  def get_date_year_segment_data_for_query()

    year_regex = /(-?\d\d\d\d)/

    max_number_of_segments = 50
    date_range_field_name = 'lib_date_year_range_si'

    year_range_response = get_facet_field_response(date_range_field_name, params, {'facet.limit' => '1000000000'})
    year_range_facet_values = []

    year_split_regex = /(-?\d\d\d\d)-(-?\d\d\d\d)/

    if year_range_response.fetch('facet_counts', {}).fetch('facet_fields', {}).fetch(date_range_field_name, {}).length == 0
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

    # If possible, use start_year and end_year to set the start_of_range and end_of_range values
    if params[:start_year].present?
      start_of_range = params[:start_year].to_i
    else
      start_of_range = earliest_start_year
    end

    if params[:end_year].present?
      end_of_range = params[:end_year].to_i
    else
      end_of_range = latest_end_year
    end

    # Generate segments
    range_size = end_of_range - start_of_range
    segment_size = 1

    if range_size < 20
      number_of_segments = range_size
      #segment_size = 1
    elsif range_size < 100
      number_of_segments = 40
      #segment_size = 5
    elsif range_size < 1000
      number_of_segments = 30
      #segment_size = 50
    elsif range_size < 10000
      number_of_segments = 30
      #segment_size = 100
    else
      number_of_segments = 30
      #segment_size = 1000
    end

    segments = []
    highest_segment_count_value = 0
    #number_of_segments = (range_size.to_f/segment_size.to_f).round(0)
    segment_size = range_size.to_f/number_of_segments.to_f

    number_of_segments.times {|i|

      start_of_segment_range = start_of_range+i*segment_size
      end_of_segment_range = start_of_segment_range + segment_size
      new_segment = {}
      new_segment[:start] = start_of_segment_range.round(0)
      new_segment[:end] = end_of_segment_range.round(0)
      new_segment[:count] = 0


      year_range_facet_values.each {|val|
        start_year = val[:start_year]
        end_year = val[:end_year]
        if (start_year <= end_of_segment_range) && (end_year >= start_of_segment_range)
          new_segment[:count] += val[:count]
        end
      }

      highest_segment_count_value = new_segment[:count] if new_segment[:count] > highest_segment_count_value
      segments << new_segment

    }

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
