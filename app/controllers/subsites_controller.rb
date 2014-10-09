class SubsitesController < ApplicationController

  include Dcv::CatalogIncludes

  def initialize(*args)
    super(*args)
    self.class.parent_prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  layout Proc.new { |controller| SUBSITES['public'][self.controller_name]['layout'] }

end
