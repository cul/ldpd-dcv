class JayController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::JayBlacklightConfigurator.configure(config)
    # Include only this target's content in search results
    config.default_solr_params[:fq] << "publisher_ssim:\"#{subsite_config['uri']}\""
  end

  def index
	super
    unless has_search_parameters?
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
