module Dcv::Catalog::SearchParamsLogicBehavior
  extend ActiveSupport::Concern

  included do
    self.solr_search_params_logic += [:file_assets_filter, :date_range_filter]
  end

  def file_assets_filter(solr_parameters, user_parameters)
    unless user_parameters[:show_file_assets] == 'true'
      solr_parameters[:fq] << '-active_fedora_model_ssi:GenericResource'
    end
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

end
