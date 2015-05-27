class JayController < SubsitesController

  configure_blacklight do |config|
    Dcv::Configurators::Restricted::JayBlacklightConfigurator.configure(config)
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


end
