require 'redcarpet'

class SitesController < ApplicationController
  include Dcv::RestrictableController
  include Dcv::CatalogIncludes

  layout Proc.new { |controller| 'dcv' }

  configure_blacklight do |config|
    config.default_solr_params = {
      :fq => [
        'object_state_ssi:A', # Active items only
        'active_fedora_model_ssi:Concept',
        'dc_type_sim:"Publish Target"'
      ],
      :qt => 'search'
    }

    # TODO: use restricted staff catalog value here?
    publisher = self.restricted? ? 'info:fedora/cul:vmcvdnck2d' : 'info:fedora/cul:vmcvdnck2d'
    config.default_solr_params[:fq] << "publisher_ssim:\"#{publisher}\""
    config.default_per_page = 20
    config.per_page = [20,60,100]
    config.max_per_page = 100

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
end