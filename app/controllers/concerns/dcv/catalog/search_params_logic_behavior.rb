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
    if user_parameters[:start_date].present?
      start_date = user_parameters[:start_date].match(/.*(\d\d\d\d-\d\d-\d\d).*/).captures[0]
      solr_parameters[:fq] << "lib_start_date_sim:[#{start_date} TO *]"
    end
    
    if user_parameters[:end_date].present?
      end_date = user_parameters[:end_date].match(/.*(\d\d\d\d-\d\d-\d\d).*/).captures[0]
      solr_parameters[:fq] << "lib_end_date_sim:[* TO #{end_date}]"
    end
    
    
  end

end
