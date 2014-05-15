require 'actionpack/action_caching'
class ScreenImageController < ActionController::Base

  include Hydra::Controller::ControllerBehavior
  include Cul::Scv::Hydra::Controller

  caches_action :show, :expires_in => 0.days
  
  def show
  	id = params[:id]
    
  end

  def relsint_solr_params
  	{
  		id: params[:id],
      qt: :document,
      fl: [solr_name('rels_int_profile', :stored_searchable), solr_name('active_fedora_model', :stored_sortable)]
  	}
  end
end