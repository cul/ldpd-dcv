class SubsitesController < ApplicationController

  include Dcv::CatalogIncludes
  include Cul::Hydra::ApplicationIdBehavior

  def initialize(*args)
    super(*args)
    self.class.parent_prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  layout Proc.new { |controller|
    self.subsite_layout
  }

  def subsite_config
    return SUBSITES[(self.class.restricted? ? 'restricted' : 'public')][self.controller_name]
  end

  def self.restricted?
    return controller_path.start_with?('restricted/')
  end

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
