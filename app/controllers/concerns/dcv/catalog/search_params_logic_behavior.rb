module Dcv::Catalog::SearchParamsLogicBehavior
  extend ActiveSupport::Concern

  included do
    self.solr_search_params_logic += [:date_range_filter, :lat_long_filter, :multiselect_facet_feature, :durst_favorite_filter]
  end

  #def file_assets_filter(solr_parameters, user_parameters)
  #  unless user_parameters[:show_file_assets] == 'true'
  #    solr_parameters[:fq] << '-active_fedora_model_ssi:GenericResource'
  #  end
  #end
  
  def hide_concepts_when_query_blank_filter(solr_parameters, user_parameters)
    solr_parameters[:fq] << '-active_fedora_model_ssi:Concept' unless user_parameters[:q].present?
  end

  def date_range_filter(solr_parameters, user_parameters)

    start_year = user_parameters[:start_year].present? ? user_parameters[:start_year].to_i : nil
    end_year = user_parameters[:end_year].present? ? user_parameters[:end_year].to_i : nil

    final_date_fq = nil

    if start_year.present? && end_year.present?
      final_date_fq = "(lib_start_date_year_itsi:[* TO #{end_year}]) AND (lib_end_date_year_itsi:[#{start_year} TO *])"
    elsif start_year.present?
      final_date_fq = "(lib_start_date_year_itsi:[#{start_year} TO *]) OR (lib_end_date_year_itsi:[#{start_year} TO *])"
    elsif end_year.present?
      final_date_fq = "(lib_start_date_year_itsi:[* TO #{end_year}]) OR (lib_end_date_year_itsi:[* TO #{end_year}])"
    end

    solr_parameters[:fq] << final_date_fq if final_date_fq.present?

  end

  def lat_long_filter(solr_parameters, user_parameters)
    lat = user_parameters[:lat].present? ? user_parameters[:lat].to_f : nil
    long = user_parameters[:long].present? ? user_parameters[:long].to_f : nil

    if lat && long
      solr_parameters[:fq] << "{!geofilt pt=#{lat},#{long} sfield=geo d=.0001}"
    end
  end

  # For facet fields with value ":multiselect => true", make them work like fq's with OR logic
  def multiselect_facet_feature(solr_parameters, user_parameters)

    blacklight_config.facet_fields.each {|field_name, facet_field|
      # Only apply this to multiselect fields (as configured in the blacklight config)
      if facet_field[:multiselect]
        if params[:f] && params[:f][field_name]
          values = []
          # Delete individual fq entries for EACH facet value
          params[:f][field_name].each {|value|
            solr_parameters['fq'].delete_if{|key,value| key.start_with?('{!raw f=' + field_name + '}')}
            values << value
          }
          # And combine all of this facet's fq values into a single OR fq
          solr_parameters['fq'] << '{!tag=' + facet_field.ex + '}' + field_name + ':("' + values.join('" OR "') + '")'
        end
      end
    }

    # How this works (using the lib_format_sim as an example):

    # In blacklight config (note the ":multiselect => true" addition):
    # config.add_facet_field ActiveFedora::SolrService.solr_name('lib_format', :facetable), :label => 'Format', :limit => 10, :sort => 'count', :multiselect => true, :ex => 'lib_format-tag'

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

  def durst_favorite_filter(solr_parameters, user_parameters)
    if user_parameters[:durst_favorites].present? && user_parameters[:durst_favorites].to_s == 'true'
      params[:search_field] = 'all_text_teim' if params[:search_field].blank?
      solr_parameters[:fq] << 'cul_member_of_ssim:"info:fedora/cul:nvx0k6djr1"' # cul:nvx0k6djr1 is the pid of the "Seymour's Favorites" Group
    end
  end

end
