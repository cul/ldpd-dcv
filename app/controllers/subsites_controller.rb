class SubsitesController < ApplicationController

  include Dcv::CatalogIncludes

  def initialize(*args)
    super(*args)
    self.class.parent_prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  layout Proc.new { |controller|
    SUBSITES[(self.class.restricted? ? 'restricted' : 'public')][self.controller_name]['layout']
  }

  def subsite_config
    return SUBSITES[(self.class.restricted? ? 'restricted' : 'public')][self.controller_name]
  end

  def self.restricted?
    return controller_path.start_with?('restricted/')
  end

end
