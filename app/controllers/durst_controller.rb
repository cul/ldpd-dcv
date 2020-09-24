class DurstController < SubsitesController
  include Dcv::MapDataController

  before_action :set_map_data_json, only: [:map_search]

  configure_blacklight do |config|
    Dcv::Configurators::DurstBlacklightConfigurator.configure(config)
    # Include this target's content in search results, and any additional publish targets specified in subsites.yml
    publishers = [subsite_config['uri']] + (subsite_config['additional_publish_targets'] || [])
    config.default_solr_params[:fq] << "publisher_ssim:(\"" + publishers.join('" OR "') + "\")"
  end

  def index
    super
    if !has_search_parameters? && request.format.html?
      # we override the view rendered for the subsite home on html requests
      render 'home'
    end
  end

  def help
  end

  def favorites
    redirect_to '/durst?durst_favorites=true&search_field=all_text_teim'
  end

  def about_the_collection
  end

  def about_the_project
  end

  def acknowledgements
  end

  def old_york_library_collection_categories
  end

  def subsite_layout
    'durst'
  end

end
