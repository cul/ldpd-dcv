require 'blacklight/catalog'

class SubsitesController < ApplicationController

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Dcv::Catalog::SearchParamsLogicBehavior
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::Catalog::DateRangeSelectorBehavior
  include Dcv::Catalog::RandomItemBehavior
  include Dcv::Catalog::PivotFacetDataBehavior
  include Dcv::Catalog::ModsDisplayBehavior
  include Dcv::Catalog::CitationDisplayBehavior

  def initialize(*args)
    super(*args)
    self.class.parent_prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  layout Proc.new { |controller| SUBSITES[self.controller_name]['layout'] }

  def add_collection_fq(solr_parameters, user_params)
    puts 'CUSTOM_COLLECTIONS: ' + CUSTOM_COLLECTIONS.inspect
    collection_id = CUSTOM_COLLECTIONS.fetch(self.controller_name, DEFAULT_COLLECTION)['collection_id']
    collection_id.strip!
    user_params = {f: {
      cul_member_of_ssim: "info:fedora/#{collection_id}"
      }}
      puts "user_params: #{user_params.inspect}"
    add_facet_fq_to_solr(solr_parameters, user_params)
    puts solr_parameters.inspect
  end

end
