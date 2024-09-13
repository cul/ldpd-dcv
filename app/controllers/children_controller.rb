# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ChildrenController < ApplicationController

  include Dcv::NonCatalog
  include Dcv::Resources::LegacyIdBehavior
  include ChildrenHelper

  respond_to :json

  configure_blacklight do |config|
    config.default_solr_params = {
      :qt => 'search',
      :rows => 12
    }
    config[:unique_key] = :id
    config.index.title_field = 'title_display_ssm'
  end

  def get_solr_response_for_app_id(id=nil, extra_controller_params={})
    id ||= params[:id]
    p = blacklight_config.default_document_solr_params.merge(extra_controller_params)
    p[:fq] = "identifier_ssim:#{(id)}"
    solr_response = find(blacklight_config.document_solr_path, p)
    raise Blacklight::Exceptions::RecordNotFound.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end

  def index
    respond_to do |format|
      format.any do
        opts = {}
        opts[:per_page] = params.fetch('per_page', '10')
        opts[:page] = params.fetch('page', '0')
        render json: children(params['parent_id'], opts), content_type: 'application/json' # Yes, content_type seems redundant here, but the header wasn't getting sent.
      end
    end
  end

  def show
    puts child(params['id']).inspect
    render json: child(params['id']), content_type: 'application/json' # Yes, content_type seems redundant here, but the header wasn't getting sent.
  end

  # shims from Blacklight 6 controller fetch to BL 7 search service
  def search_service
    Blacklight::SearchService.new(config: blacklight_config, user_params: {})
  end

  def fetch(id = nil, extra_controller_params = {})
    return search_service.fetch(id, extra_controller_params)
  end
end
