# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  DATE_END_FIELD_NAME = 'lib_end_date_year_itsi'
  DATE_RANGE_FIELD_NAME = 'lib_date_year_range_si'
  DATE_START_FIELD_NAME = 'lib_start_date_year_itsi'

  self.default_processor_chain += [
    :date_range_filter, :lat_long_filter, :multiselect_facet_feature,
    :durst_favorite_filter
  ]

  def date_range_filter(solr_params)

    start_year = blacklight_params[:start_year].present? ? blacklight_params[:start_year].to_i : nil
    end_year = blacklight_params[:end_year].present? ? blacklight_params[:end_year].to_i : nil

    final_date_fq = nil

    if start_year.present? && end_year.present?
      final_date_fq = "(lib_start_date_year_itsi:[* TO #{end_year}]) AND (lib_end_date_year_itsi:[#{start_year} TO *])"
    elsif start_year.present?
      final_date_fq = "(lib_start_date_year_itsi:[#{start_year} TO *]) OR (lib_end_date_year_itsi:[#{start_year} TO *])"
    elsif end_year.present?
      final_date_fq = "(lib_start_date_year_itsi:[* TO #{end_year}]) OR (lib_end_date_year_itsi:[* TO #{end_year}])"
    end

    solr_params[:fq] ||= []
    solr_params[:fq] << final_date_fq if final_date_fq.present?
    solr_params
  end

  def lat_long_filter(solr_params)
    lat = blacklight_params[:lat].present? ? blacklight_params[:lat].to_f : nil
    long = blacklight_params[:long].present? ? blacklight_params[:long].to_f : nil

    if lat && long
      solr_params[:fq] ||= []
      solr_params[:fq] << "{!geofilt pt=#{lat},#{long} sfield=geo d=.0001}"
    end
    solr_params
  end

  # For facet fields with value ":multiselect => true", make them work like fq's with OR logic
  def multiselect_facet_feature(solr_params)
    solr_params[:fq] ||= []
    blacklight_config.facet_fields.each {|field_name, facet_field|
      # Only apply this to multiselect fields (as configured in the blacklight config)
      if facet_field[:multiselect]
        if blacklight_params[:f] && blacklight_params[:f][field_name]
          values = []
          # Delete individual fq entries for EACH facet value
          blacklight_params[:f][field_name].each {|value|
            solr_params[:fq].delete_if{|key,value| key.start_with?('{!term f=' + field_name + '}')}
            values << value
          }
          # And combine all of this facet's fq values into a single OR fq
          solr_params[:fq] << '{!tag=' + facet_field.ex + '}' + field_name + ':("' + values.join('" OR "') + '")'
        end
      end
    }
    solr_params

    # How this works (using the lib_format_sim as an example):

    # In blacklight config (note the ":multiselect => true" addition):
    # config.add_facet_field 'lib_format_sim', :label => 'Format', :limit => 10, :sort => 'count', :multiselect => true, :ex => 'lib_format-tag'

    #{
    #  "facet.field"=>[
    #      "{!ex=lib_format}lib_format_sim",
    #      "lib_hierarchical_geographic_borough_ssim",
    #      "lib_hierarchical_geographic_neighborhood_ssim",
    #      "lib_hierarchical_geographic_city_ssim",
    #      "{!ex=lib_format}lib_format_sim",
    #      "lib_hierarchical_geographic_borough_ssim",
    #      "lib_hierarchical_geographic_neighborhood_ssim",
    #      "lib_hierarchical_geographic_city_ssim"
    #  ],
    #  "facet.query"=>[
    #
    #  ],
    #  "facet.pivot"=>[
    #
    #  ],
    #  "fq"=>[
    #      "lib_project_short_ssim:\"Durst\"",
    #      "-active_fedora_model_ssi:GenericResource",
    #      "{!tag=lib_format}lib_format_sim:(\"books\" OR \"prints\")"
    #  ],
    #  "hl.fl"=>[
    #
    #  ],
    #  "qt"=>"search",
    #  "rows"=>20,
    #  "qf"=>[
    #      "all_text_teim"
    #  ],
    #  "pf"=>[
    #      "all_text_teim"
    #  ],
    #  "q"=>"",
    #  "spellcheck.q"=>"",
    #  "facet"=>true,
    #  "f.lib_format_sim.facet.sort"=>"count",
    #  "f.lib_format_sim.facet.limit"=>11,
    #  "f.lib_hierarchical_geographic_borough_ssim.facet.sort"=>"count",
    #  "f.lib_hierarchical_geographic_borough_ssim.facet.limit"=>11,
    #  "f.lib_hierarchical_geographic_neighborhood_ssim.facet.sort"=>"count",
    #  "f.lib_hierarchical_geographic_neighborhood_ssim.facet.limit"=>11,
    #  "f.lib_hierarchical_geographic_city_ssim.facet.sort"=>"count",
    #  "f.lib_hierarchical_geographic_city_ssim.facet.limit"=>11,
    #  "sort"=>"score desc, title_si asc, lib_date_dtsi desc"
    #}
  end

  def durst_favorite_filter(solr_params)
    if blacklight_params[:durst_favorites].present? && blacklight_params[:durst_favorites].to_s == 'true'
      solr_params[:search_field] = 'all_text_teim' if solr_params[:search_field].blank?
      solr_params[:fq] ||= []
      solr_params[:fq] << 'cul_member_of_ssim:"info:fedora/cul:nvx0k6djr1"' # cul:nvx0k6djr1 is the pid of the "Seymour's Favorites" Group
    end
    solr_params
  end

  def hide_concepts_when_query_blank_filter(solr_params)
    unless solr_params[:q].present?
      solr_params[:fq] ||= []
      solr_params[:fq] << '-active_fedora_model_ssi:Concept'
    end
    solr_params
  end

  def constrain_to_repository_context(solr_params)
    if blacklight_params[:repository_id].present?
      solr_params[:fq] ||= []
      if blacklight_params[:repository_id] == 'NNC-RB'
        fq = 'lib_repo_code_ssim:("' + ['NNC-RB', 'NyNyCOH', 'NNC-UA'].join('" OR "') + '")'
      else
        fq = "lib_repo_code_ssim:\"#{blacklight_params[:repository_id]}\""
      end
      solr_params[:fq] << fq
    end
    solr_params
  end

  def constrain_to_slug(solr_params)
    if blacklight_params[:slug].present?
      solr_params[:fq] ||= []
      solr_params[:fq] << "slug_ssim:\"#{blacklight_params[:slug]}\""
    end
    solr_params
  end

  def constrain_to_public_sites(solr_params)
    constrain_by_publisher(solr_params, SUBSITES['public']['uri'])
  end

  def constrain_to_restricted_sites(solr_params)
    constrain_by_publisher(solr_params, SUBSITES['restricted']['uri'])
  end

  def constrain_by_publisher(solr_params, publisher_constraint)
      solr_params[:fq] ||= []
      solr_params[:fq] << "publisher_ssim:\"#{publisher_constraint}\""
      solr_params
  end

  def filter_random_suppressed_content(solr_params)
    solr_params[:fq] ||= []
    solr_params[:fq] << "!suppress_in_random_bsi:true"
    solr_params
  end

  def remove_cmodel_filters(solr_params)
    (solr_params[:fq] ||= []).delete_if { |fq| fq.starts_with?("active_fedora_model_ssi:")} 
  end
  def add_date_range_json_facets(solr_params)
    solr_params[:"facet.field"] = [DATE_RANGE_FIELD_NAME]
    solr_params[:"f.#{DATE_RANGE_FIELD_NAME}.facet.limit"] = -1
    solr_params[:rows] = 0
    solr_params[:json] ||= { facet: {} }
    (solr_params[:json][:facet] ||= {}).merge!({
      DATE_START_FIELD_NAME => {
        field: DATE_START_FIELD_NAME,
        type: 'terms',
        limit: 1, sort: 'index asc'
      },
      DATE_END_FIELD_NAME => {
        field: DATE_END_FIELD_NAME,
        type: 'terms',
        limit: 1, sort: 'index desc'
      }
    })
  end
end
