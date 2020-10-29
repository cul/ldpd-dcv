module Dcv
  class Routes::SiteSearchable
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options)
      mapper.match '/', action: 'index', as: 'search', via: [:get, :post]

      mapper.get "opensearch"
      mapper.get "facet/:id", action: 'facet', as: 'facet'
    end
  end
end
