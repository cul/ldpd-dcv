require 'actionpack/action_caching'
class ScreenImagesController < ApplicationController

  include Dcv::NonCatalog
  include Hydra::Controller::ControllerBehavior
  include Dcv::Resources::RelsIntBehavior
  include Cul::Scv::Hydra::Controller

  caches_action :show, :expires_in => 0.days

  respond_to :png, :jpeg, :gif

  layout 'dcv'

  configure_blacklight do |config|
    config.default_solr_params = {
      :qt => 'search',
      :rows => 12
    }
    config[:unique_key] = :id
    config.index.title_field = solr_name('title_display', :displayable, type: :string)
  end

  def show
  	id = params[:id]
    @response, @document = get_solr_response_for_doc_id(params[:id])
    resources = resources_for_document
    resource = nil
    resources.each do |r|
      if r[:length] and r[:width]
        w = r[:width].to_i
        l = r[:length].to_i
        if (w <= 1200 and l <=1200)
          if resource.nil?
            resource = r
          else
            resource = r if w > resource[:width].to_i
          end
        end
      end
    end
    if resource.nil?
      raise ActiveRecord::RecordNotFound.new(resources.inspect)
    end
    ds_parms = {pid: params[:id], dsid: resource[:id].split('/')[-1]}
    response.headers["Last-Modified"] = Time.now.to_s
    puts ds_parms.inspect()
    ds = Cul::Scv::Fedora.ds_for_opts(ds_parms)
    size = params[:file_size] || params['file_size']
    size ||= ds.dsSize

    ###########################
    unless size and size.to_i > 0
      response.headers["Transfer-Encoding"] = ["chunked"]
    else
      response.headers["Content-Length"] = [size]
    end
    response.headers["Content-Type"] = ds.mimeType

    self.response_body = Enumerator.new do |blk|
      repo = ActiveFedora::Base.connection_for_pid(ds_parms[:pid])
      repo.datastream_dissemination(ds_parms) do |res|
        res.read_body do |seg|
          blk << seg
        end
      end
    end
    ###########################
    # TODO: Eventually use new Rails streaming method
#    if size and size.to_i > 0
#			response.headers["Content-Length"] = size
#		end
#    bytes = 0
#    repo = ActiveFedora::Base.connection_for_pid(ds_parms[:pid])
#    repo.datastream_dissemination(ds_parms) do |res|
#			begin
#				res.read_body do |seg|
#					response.stream.write seg
#					bytes += seg.length
#				end
#			ensure
#				response.stream.close
#			end
#		end
		###########################

  end

  def relsint_solr_params
  	{
  		id: params[:id],
      qt: :document,
      fl: [solr_name('rels_int_profile', :stored_searchable), solr_name('active_fedora_model', :stored_sortable)]
  	}
  end

  def solr_name(*args)
    ActiveFedora::SolrService.solr_name(*args)
  end
end
