class PagesController < ApplicationController

  layout 'dcv'

  def wall
  end

  def about
  end

  def repository
    Blacklight.default_index
  end
end
