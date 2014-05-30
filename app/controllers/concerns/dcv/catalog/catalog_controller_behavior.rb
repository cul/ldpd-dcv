module Dcv::Catalog::CatalogControllerBehavior
  extend ActiveSupport::Concern

  included do
    CatalogController.solr_search_params_logic += [:exclude_groups_and_files_by_default]
  end

  def exclude_groups_and_files_by_default(solr_parameters, user_parameters)
    if params[:search].blank?
        params[:f] ||= {}
        params[:f]['active_fedora_model_ssi'] = ['exclude_groups', 'exclude_files']
        params[:search] = 'true'
    end
  end

end
