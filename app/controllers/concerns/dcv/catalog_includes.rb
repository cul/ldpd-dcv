require 'blacklight/catalog'

module Dcv::CatalogIncludes
  extend ActiveSupport::Concern

  include Blacklight::Catalog
  include Dcv::Catalog::BrowseListBehavior
  include Dcv::Catalog::CachedFetchBehavior
  include Dcv::Catalog::DateRangeSelectorBehavior
  include Dcv::Catalog::RandomItemBehavior
  include Dcv::Catalog::PivotFacetDataBehavior
  include Dcv::Catalog::ModsDisplayBehavior
  include Dcv::Catalog::CitationDisplayBehavior
  include Dcv::Catalog::AssetResolverBehavior
  include Dcv::Catalog::CsvDownloadBehavior
end
