class DetailsController < SubsitesController
  include Dcv::CatalogIncludes
  include Dcv::Sites::SearchableController
  include Dcv::Sites::ConfiguredLayouts
  include Dcv::Catalog::CatalogLayout

  layout 'details'

  _prefixes << 'catalog' # haaaaaaack to not reproduce templates

  configure_blacklight do |config|
    config.search_state_fields.concat(Dcv::Configurators::BaseBlacklightConfigurator::Constants::DETAILS_PARAMS)
    Dcv::Configurators::DcvBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    configure_blacklight_scope_constraints(config, true)
    config.add_facet_field 'content_availability', label: 'Limit by Availability', show: false,
      query: {
        onsite: { label: 'Reading Room', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}!access_control_levels_ssim:Public*" },
        public: { label: 'Public', fq: "{!join from=cul_member_of_ssim to=fedora_pid_uri_ssi}access_control_levels_ssim:Public*" },
      }
  end

  def show
    id = params[:id]
    @response, @document = fetch(params[:id])
  end

  def embed
    id = params[:id]
    @response, @document = fetch "doi:#{params[:id]}", q: "{!raw f=ezid_doi_ssim v=$ezid_doi_ssim}"
    if can?(Ability::ACCESS_ASSET, @document)
      response.headers.delete 'X-Frame-Options'
    else
      render file: 'public/404.html', layout: false, status: 404
      return
    end
  end
end
