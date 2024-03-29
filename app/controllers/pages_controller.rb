class PagesController < ApplicationController
  include Dcv::Sites::ConfiguredLayouts
  include Dcv::Catalog::CatalogLayout

  layout Proc.new { |controller|
    controller.subsite_layout
  }

  def initialize(*args)
    super(*args)
    # _prefixes are where view path lookups are attempted; probably unnecessary
    # but need testing. default blank value should be first, but layout needs to be in front of controller path
    self._prefixes.unshift "shared"
    self._prefixes.unshift self.subsite_layout
    self._prefixes.unshift self.subsite_key
    self._prefixes.unshift ""
  end

  # view paths look up partial templates within _prefixes
  # paths are relative to Rails.root
  # prepending because we want to give specialized path priority
  def set_view_path
    super
    prepend_view_path('app/views/' + self.subsite_layout)
    prepend_view_path('app/views/' + controller_path)
  end

  def wall
  end

  def about
  end

  def tombstone
  end

  def repository
    Blacklight.default_index
  end
end
