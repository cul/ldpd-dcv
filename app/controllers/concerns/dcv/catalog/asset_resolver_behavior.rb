module Dcv::Catalog::AssetResolverBehavior
  extend ActiveSupport::Concern

  def get_solr_response_for_app_id(id=nil, extra_controller_params={})
    id ||= params[:id]
    id.sub!(/apt\:\/columbia/,'apt://columbia') # TOTAL HACK
    id.gsub!(':','\:')
    id.gsub!('/','\/')
    p = blacklight_config.default_document_solr_params.merge(extra_controller_params)
    p[:fq] = "identifier_ssim:#{(id)}"
    solr_response = find(blacklight_config.document_solr_path, p)
    raise Blacklight::Exceptions::InvalidSolrID.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end

  def asset
    redirect_to(DCV_CONFIG['cdn_url'] + "/images/#{params[:id]}/#{params[:type]}/#{params[:size]}.#{params[:format]}")
  end

  def resolve_asset
    get_solr_response_for_app_id
    redirect_to(DCV_CONFIG['cdn_url'] + "/images/#{@document.id}/#{params[:type]}/#{params[:size]}.#{params[:format]}")
  end

  def asset_info
    redirect_to(DCV_CONFIG['cdn_url'] + "/images/#{params[:id]}/#{params[:image_format]}.json")
  end

  def resolve_asset_info
    get_solr_response_for_app_id
    redirect_to(DCV_CONFIG['cdn_url'] + "/images/#{@document.id}/#{params[:image_format]}.json")
  end

end
