module Dcv::CatalogHelperBehavior
  def url_for_children_data(per_page=nil)
    opts = {id: params[:id]}
    opts[:per_page] = per_page || 4
    opts[:protocol] = (request.protocol =~ /^https/) ? 'https' : 'http'
    children_url(opts)
  end
end