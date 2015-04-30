class SubsitesController < ApplicationController

  include Dcv::CatalogIncludes
  include Cul::Hydra::ApplicationIdBehavior

  before_filter :set_view_path

  layout Proc.new { |controller|
    self.subsite_layout
  }

  def initialize(*args)
    super(*args)
    self.class.parent_prefixes << self.subsite_layout # haaaaaaack to not reproduce templates
    self.class.parent_prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  def set_view_path
    self.prepend_view_path('ifp')
  end

  def subsite_config
    return SUBSITES[(self.class.restricted? ? 'restricted' : 'public')][self.controller_name]
  end

  def self.restricted?
    return controller_path.start_with?('restricted/')
  end
  
  # POST /subsite/index_object
  def index_object
    pid = params[:pid]
    api_key = params[:api_key]
    
    if api_key == DCV_CONFIG['remote_request_api_key']
      # Queue for reindex
      # Since we only have one solr index right now, all index requests to go the main core
      Dcv::Queue.index_object({'pid' => pid, 'subsite_keys' => ['catalog']})
      render json: {
        "success" => true
      }
    else
      render json: {
        "error" => "Invalid credentials"
      },
      status: 401
    end
  end

  # GET /subsite/:id
  def show
    params[:format] = 'html'
    super
  end

  def preview
    @response, @document = get_solr_response_for_doc_id(params[:id], fl:'*')
    render layout: 'preview'
  end

  def subsite_key
    return (self.class.restricted? ? 'restricted_' : '') + self.controller_name
  end

  def subsite_layout
    SUBSITES[(self.class.restricted? ? 'restricted' : 'public')][self.controller_name]['layout']
  end

end
