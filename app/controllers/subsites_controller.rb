require 'blacklight/catalog'

class SubsitesController < ApplicationController

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Dcv::Catalog::SearchParamsLogicBehavior
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::Catalog::DateRangeSelectorBehavior
  include Dcv::Catalog::RandomItemBehavior
  include Dcv::Catalog::PivotFacetDataBehavior
  include Dcv::Catalog::ModsDisplayBehavior
  include Dcv::Catalog::CitationDisplayBehavior

  def initialize(*args)
    super(*args)
    self.class.parent_prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  layout Proc.new { |controller| SUBSITES[self.controller_name]['layout'] }

end
