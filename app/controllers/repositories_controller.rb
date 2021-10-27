require 'redcarpet'

class RepositoriesController < ApplicationController
  include Dcv::CatalogIncludes
  include Dcv::CdnHelper

  layout Proc.new { |controller| 'dcv' }

  configure_blacklight do |config|
    config.default_solr_params = {
      :fq => [
        'object_state_ssi:A', # Active items only
        'active_fedora_model_ssi:Concept',
        'dc_type_sim:"Publish Target"',
        '-slug_ssim:sites', # Do not include sites publish targets in this list
      ],
      :sort => "title_si asc",
      :qt => 'search'
    }
    config.add_search_field ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text) do |field|
      field.label = 'All Fields'
      field.default = true
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)]
      }
    end
  end

  before_action :set_repository_id, only:[:show]

  def initialize(*args)
    super(*args)
    self._prefixes.unshift 'repositories'
  end

  def search_builder
    super.tap { |builder| builder.processor_chain.concat [:constrain_to_repository_context] }
  end

  def set_view_path
    super
    self.prepend_view_path('app/views/repositories')
  end

  def set_repository_id
    params[:repository_id] = params[:id] # routing hack for sanity in the partials
  end

  ##
  # If the current action should start a new search session, this should be
  # set to true
  # see also Blacklight::Catalog::SearchContext
  def start_new_search_session?
    true
  end

  def digital_projects(restricted = false)
    unless @document_list
      (@response, @document_list) = search_results(params)
    end
    @document_list.map do |solr_doc|
      t = {
        name: strip_restricted_title_qualifier(solr_doc.fetch('title_ssm',[]).first),
        image: thumbnail_url(solr_doc),
        external_url: solr_doc.fetch('source_ssim',[]).first, # TODO: Handle landing page sites in this context
        description: solr_doc.fetch('abstract_ssim',[]).first,
        search_scope: solr_doc.fetch('search_scope_ssi', "project") || "project"
      }
      t[:facet_value] = solr_doc.fetch('short_title_ssim',[]).first if published_to_catalogs?(solr_doc)
      t[:facet_field] = (t[:search_scope] == 'collection') ? 'lib_collection_sim' : 'lib_project_short_ssim'
      unless t[:external_url]
        t[:external_url] = solr_doc[:restriction_ssim].present? ? restricted_site_url(solr_doc.fetch('slug_ssim',[]).first) : site_url(solr_doc.fetch('slug_ssim',[]).first)
      end
      t
    end
  end

  def strip_restricted_title_qualifier(qualified_title)
    unqualified_title = qualified_title.dup
    unqualified_title.sub!(/\s*[\[\(]Restricted[\)\]]\s*/i, '')
    unqualified_title
  end

  def published_to_catalogs?(document={})
    document && (document.fetch('publisher_ssim',[]) & catalog_uris).present?
  end

  def catalog_uris
    ['restricted', 'public'].map { |top| SUBSITES[top].fetch('catalog',{})['uri'] }.compact
  end

  def site_uri(restricted = false)
    top = restricted ? 'restricted' : 'public'
    SUBSITES[top].fetch('sites',{})['uri']
  end

  def show
    redirect_to repository_reading_room_path(repository_id: params[:id])
  end

  def reading_room
    template_key = params[:repository_id].downcase
    template_key.gsub!("-","")
    render "reading_room/#{template_key}/show"
  end

  def reading_room_client?
    (repository_ids_for_client & [params[:repository_id]]).present?
  end

  def repository_ids_for_client(remote_ip = request.remote_ip)
    Rails.application.config_for(:location_uris).map do |location_uri, location|
      if location.fetch('remote_ip', []).include?(remote_ip.to_s)
        location.fetch('repository_id', nil)
      end
    end.compact
  end

  # Overrides the Blacklight::Controller provided #search_action_url.
  # By default, any search action from a Blacklight::Catalog controller
  # should use the current controller when constructing the route.
  # see also HomeController
  def search_action_url options = {}
    url_for(options.merge(:action => 'index', :controller=>'catalog'))
  end
end
