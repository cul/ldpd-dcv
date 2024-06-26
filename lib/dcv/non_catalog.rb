# -*- encoding : utf-8 -*-
module Dcv::NonCatalog
  extend ActiveSupport::Concern
  
  include Blacklight::Configurable
  include Blacklight::Base


  # The following code is executed when someone includes blacklight::catalog in their
  # own controller.
  included do
    helper_method :has_search_parameters?

    # Whenever an action raises Blacklight::Exceptions::RecordNotFound, this block gets executed.
    # Hint: the Blacklight::SearchHelper#fetch method raises this error,
    # which is used in the #show action here.
    rescue_from Blacklight::Exceptions::RecordNotFound, :with => :invalid_solr_id_error
    rescue_from RSolr::Error::Http, :with => :rsolr_request_error if respond_to? :rescue_from
  end
  
    # get search results from the solr index
    def index
      (@response, @document_list) = get_search_results
      
      respond_to do |format|
        format.html { }
        format.rss  { render :layout => false }
        format.atom { render :layout => false }
        format.json do
          render json: render_search_results_as_json
        end

        additional_response_formats(format)
        document_export_formats(format)
      end
    end
    
    # get single document from the solr index
    def show
      @response, @document = fetch

      respond_to do |format|
        format.html do
          @search_context = setup_next_and_previous_documents || {}
        end

        format.json { render json: {response: {document: @document}}}

        # Add all dynamically added (such as by document extensions)
        # export formats.
        @document.export_formats.each_key do | format_name |
          # It's important that the argument to send be a symbol;
          # if it's a string, it makes Rails unhappy for unclear reasons. 
          format.send(format_name.to_sym) { render plain: @document.export_as(format_name), layout: false }
        end
      end
    end

    ##
    # Check if any search parameters have been set
    # @return [Boolean] 
    def has_search_parameters?
      !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank?
    end
    
    protected    
    #
    # non-routable methods ->
    #

    ##
    # Render additional response formats, as provided by the blacklight configuration
    def additional_response_formats format
      blacklight_config.index.respond_to.each do |key, config|
        format.send key do
          case config
          when false
            raise ActionController::RoutingError.new('Not Found')
          when Hash
            render config
          when Proc
            instance_exec &config
          when Symbol, String
            send config
          else
            # no-op, just render the page
          end
        end
      end
    end

    ##
    # Try to render a response from the document export formats available
    def document_export_formats format
      format.any do
        format_name = params.fetch(:format, '').to_sym

        if @response.export_formats.include? format_name
          render_document_export_format format_name
        else
          raise ActionController::UnknownFormat.new
        end
      end
    end

    ##
    # Render the document export formats for a response
    # First, try to render an appropriate template (e.g. index.endnote.erb)
    # If that fails, just concatenate the document export responses with a newline. 
    def render_document_export_format format_name
      begin
        render
      rescue ActionView::MissingTemplate
        render text: @response.documents.map { |x| x.export_as(format_name) if x.exports_as? format_name }.compact.join("\n"), layout: false
      end    
    end

    # override this method to change the JSON response from #index 
    def render_search_results_as_json
      {response: {docs: @document_list, facets: search_facets_as_json, pages: pagination_info(@response)}}
    end

    def search_facets_as_json
      facets_from_request.as_json.each do |f|
        f.delete "options"
        f["label"] = facet_configuration_for_field(f["name"]).label
        f["items"] = f["items"].as_json.each do |i|
          i['label'] ||= i['value']
        end
      end 
    end

    # override this method to change the JSON response from #facet 
    def render_facet_list_as_json
      {response: {facets: @pagination }}
    end

    # Overrides the Blacklight::Controller provided #search_action_url.
    # By default, any search action from a Blacklight::Catalog controller
    # should use the current controller when constructing the route.
    def search_action_url options = {}
      url_for(options.merge(:action => 'index'))
    end
    
    # when a request for /catalog/BAD_SOLR_ID is made, this method is executed.
    # Just returns a 404 response, but you can override locally in your own
    # CatalogController to do something else -- older BL displayed a Catalog#inde
    # page with a flash message and a 404 status.
    def invalid_solr_id_error(exception)
      error_info = {
        "status" => "404",
        "error"  => "#{exception.class}: #{exception.message}"
      }

      respond_to do |format|
        format.xml  { render :xml  => error_info, :status => 404 }
        format.json { render :json => error_info, :status => 404 }

        # default to HTML response, even for other non-HTML formats we don't
        # neccesarily know about, seems to be consistent with what Rails4 does
        # by default with uncaught ActiveRecord::RecordNotFound in production
        format.any do
          # use standard, possibly locally overridden, 404.html file. Even for
          # possibly non-html formats, this is consistent with what Rails does
          # on raising an ActiveRecord::RecordNotFound. Rails.root IS needed
          # for it to work under testing, without worrying about CWD.
          render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false, :content_type => 'text/html'
        end
      end
    end
  protected

  # when solr (RSolr) throws an error (RSolr::RequestError), this method is executed.
  def rsolr_request_error(exception)

    if Rails.env.development? || Rails.env.test?
      raise exception # Rails own code will catch and give usual Rails error page with stack trace
    else

      flash_notice = I18n.t('blacklight.search.errors.request_error')

      # If there are errors coming from the index page, we want to trap those sensibly

      if flash[:notice] == flash_notice
        logger.error "Cowardly aborting rsolr_request_error exception handling, because we redirected to a page that raises another exception"
        raise exception
      end

      logger.error exception

      flash[:notice] = flash_notice 
      redirect_to root_path
    end
  end
end