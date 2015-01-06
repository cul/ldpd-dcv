# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class PreviewsController < ApplicationController
  include Blacklight::Catalog
  include Cul::Hydra::ApplicationIdBehavior
  include Hydra::Controller::ControllerBehavior
  include Cul::Scv::BlacklightConfiguration
  include CatalogHelper
  
  configure_blacklight do |config|
    configure_for_scv(config)
  end
  
  before_filter :require_roles, :only=>[:index, :show]
  
  # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
  # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
  # which is used in the #show action here.
  rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :invalid_solr_id_error

  
  # When RSolr::RequestError is raised, the rsolr_request_error method is executed.
  # The index action will more than likely throw this one.
  # Example, when the standard query parser is used, and a user submits a "bad" query.
  rescue_from RSolr::Error::Http, :with => :rsolr_request_error
  def show
    @response, @document = get_solr_response_for_dc_id

    render layout: 'preview'
    puts @document.inspect
  end

  def self.authorized_roles
    @authorized_roles ||= ROLES_CONFIG[:catalog]
  end
end
