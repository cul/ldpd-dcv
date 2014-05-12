require 'actionpack/action_caching'
class ThumbsController < ActionController::Base

  include Hydra::Controller::ControllerBehavior
  include Cul::Scv::Hydra::Controller
  include Cul::Scv::Hydra::Thumbnails
  caches_action :show, :expires_in => 7.days
  

end
