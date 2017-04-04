require 'redcarpet'

class SitesController < ApplicationController
  include Dcv::RestrictableController
  include Dcv::CatalogIncludes
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::CdnHelper

  before_filter :set_browse_lists, only: :index

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

    publisher = self.restricted? ? SUBSITES['restricted']['uri'] : SUBSITES['public']['uri']
    config.default_solr_params[:fq] << "publisher_ssim:\"#{publisher}\""
    config.default_per_page = 250
    config.per_page = [20,60,100,250]
    config.max_per_page = 250

    # solr field configuration for search results/index views
    config.index.title_field = solr_name('title', :facetable, type: :string)
    config.index.display_type_field = ActiveFedora::SolrService.solr_name('active_fedora_model', :stored_sortable)

    config.add_index_field ActiveFedora::SolrService.solr_name('abstract', :symbol, type: :string), :label => 'Abstract'
    config.add_index_field ActiveFedora::SolrService.solr_name('schema_image', :symbol, type: :string), :label => 'Representative Image'
    config.add_index_field ActiveFedora::SolrService.solr_name('short_title', :symbol, type: :string), :label => 'Facet Value'
    config.add_index_field ActiveFedora::SolrService.solr_name('slug', :symbol, type: :string), :label => 'Slug'
    config.add_index_field ActiveFedora::SolrService.solr_name('source', :symbol, type: :string), :label => 'Site URL'
    config.add_index_field ActiveFedora::SolrService.solr_name('title', :symbol, type: :string), :label => 'Title'

    config.show.title_field = solr_name('title_display', :displayable, type: :string)
    config.add_show_field ActiveFedora::SolrService.solr_name('description', :displayable, type: :string), :label => 'Description'
    config.add_show_field ActiveFedora::SolrService.solr_name('schema_image', :symbol, type: :string), :label => 'Representative Image'
    config.add_show_field ActiveFedora::SolrService.solr_name('short_title', :symbol, type: :string), :label => 'Facet Value'
    config.add_show_field ActiveFedora::SolrService.solr_name('slug', :symbol, type: :string), :label => 'Slug'
    config.add_show_field ActiveFedora::SolrService.solr_name('source', :symbol, type: :string), :label => 'Site URL'
    config.add_show_field ActiveFedora::SolrService.solr_name('title', :symbol, type: :string), :label => 'Title'
    config.add_sort_field 'title_si asc', :label => 'title'
    
    # All Text search configuration, used by main search pulldown.
    config.add_search_field ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text) do |field|
      field.label = 'All Fields'
      field.default = true
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('all_text', :searchable, type: :text)]
      }
    end

    config.add_search_field ActiveFedora::SolrService.solr_name('search_title_info_search_title', :searchable, type: :text) do |field|
      field.label = 'Title'
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('title', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('title', :searchable, type: :text)]
      }
    end

    config.add_search_field ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text) do |field|
      field.label = 'Name'
      field.solr_parameters = {
        :qf => [ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text)],
        :pf => [ActiveFedora::SolrService.solr_name('lib_name', :searchable, type: :text)]
      }
    end
  end
  
  def index
    respond_to do |format|
      format.json {
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET'
        (@response, @document_list) = get_search_results(params)
        render json: digital_projects
      }
      format.any { super }
    end
  end

  def initialize(*args)
    super(*args)
    self._prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  ##
  # If the current action should start a new search session, this should be
  # set to true
  # see also Blacklight::Catalog::SearchContext
  def start_new_search_session?
    true
  end

  # get single document from the solr index
  # override to use :slug and publisher_ssim in search to get document
  def show
    fq = solr_search_params.fetch(:fq,[])
    fq << "slug_ssim:\"#{params[:slug]}\""
    (@response, @document_list) = get_search_results(params, {fq: fq})
    @document = @document_list.first
    if @document.nil?
      render status: :not_found, text: "#{params[:slug]} is not a subsite"
      return
    end
    respond_to do |format|
      format.json { render json: {response: {document: @document}}}
      format.html { }

      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons. 
        format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
      end
    end
  end

  def markdown_renderer
    @markdown_renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML,
      autolink: true, tables: true, filter_html: true)
  end

  def render_markdown(markdown)
    markdown_renderer.render(markdown).html_safe
  end

  # used in :index action
  def digital_projects
    @document_list.sort_by{|doc|
      # Sort by title, ignoring articles. Also strip leading and trailing whitespace.
      # Note: This is a bad way to do this. We shold be indexing the
      # non-sort portion of the title into solr and sorting by that instead.
      (doc['title_display_ssm'].present? ? doc['title_display_ssm'].first.strip.gsub(/^[Aa]\s|[Aa]n\s|[Tt]he\s/, '').strip : '')
    }.each.map do |solr_doc|
      t = {
        name: solr_doc.fetch('title_display_ssm',[]).first,
        image: thumbnail_url(solr_doc),
        external_url: solr_doc.fetch('source_ssim',[]).first || site_url(solr_doc.fetch('slug_ssim',[]).first),
        description: solr_doc.fetch('abstract_ssim',[]).first
      }
      t[:facet_value] = solr_doc.fetch('short_title_ssim',[]).first if published_to_catalog?(solr_doc)
      t
    end
  end

  def published_to_catalog?(document={})
    document && document.fetch('publisher_ssim',[]).include?(catalog_uri)
  end

  def catalog_uri
    SUBSITES[self.restricted? ? 'restricted' : 'public'].fetch('catalog',{})['uri']
  end

  # Overrides the Blacklight::Controller provided #search_action_url.
  # By default, any search action from a Blacklight::Catalog controller
  # should use the current controller when constructing the route.
  # see also HomeController
  def search_action_url options = {}
    url_for(options.merge(:action => 'index', :controller=>'catalog'))
  end
  
  def set_browse_lists
    @browse_lists = get_catalog_browse_lists
  end

end