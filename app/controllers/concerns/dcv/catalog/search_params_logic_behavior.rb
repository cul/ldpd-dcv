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
      start_year = zero_pad_year(user_parameters[:start_year])
      solr_parameters[:fq] << "lib_start_date_year_ssi:[#{start_year} TO *]"
    end

    if user_parameters[:end_year].present?
      end_year = zero_pad_year(user_parameters[:end_year])
      solr_parameters[:fq] << "lib_end_date_year_ssi:[* TO #{end_year}]"
    end
  end

  def zero_pad_year(year)
    year = year.to_s
    is_negative = year.start_with?('-')
    year_without_sign = (is_negative ? year[1, year.length]: year)
    if year_without_sign.length < 4
      year_without_sign = year_without_sign.rjust(4, '0')
    end

    return (is_negative ? '-' : '') + year_without_sign
  end

end
