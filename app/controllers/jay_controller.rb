class JayController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::JayBlacklightConfigurator.configure(config)
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

  def about
  end

  def collection
  end

  def bibliography
  end

  def participating_institutions
  end

  def biography
  end

  def jay_constitution
  end

  def jay_jayandny
  end

  def jay_jaytreaty
  end

  def jay_jayandfrance
  end

  def jay_jayandslavery
  end


end
