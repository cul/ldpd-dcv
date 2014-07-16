module Dcv::Catalog::SearchParamsLogicBehavior
  extend ActiveSupport::Concern

  included do
    CatalogController.solr_search_params_logic += [:file_assets_filter, :date_range_filter]
  end

  def file_assets_filter(solr_parameters, user_parameters)
    unless user_parameters[:show_file_assets] == 'true'
      solr_parameters[:fq] << '-active_fedora_model_ssi:GenericResource'
    end
  end

  def date_range_filter(solr_parameters, user_parameters)
    if user_parameters[:start_year].present?
      start_year = Dcv::Utils::StringUtils.zero_pad_year(user_parameters[:start_year])
      if start_year.start_with?('-')
        # Handle negative BCE Date
        solr_parameters[:fq] << "lib_start_date_year_ssi:([-0001 TO #{start_year}] OR [0000 TO 9999])"
      else
        solr_parameters[:fq] << "lib_start_date_year_ssi:[#{start_year} TO 9999]"
      end
    end

    if user_parameters[:end_year].present?
      end_year = Dcv::Utils::StringUtils.zero_pad_year(user_parameters[:end_year])
      if end_year.start_with?('-')
        # Handle negative BCE Date
        solr_parameters[:fq] << "lib_end_date_year_ssi:[#{end_year} TO -9999]"
      else
        solr_parameters[:fq] << "lib_end_date_year_ssi:[0000 TO #{end_year}]"
      end
    end
  end

end
