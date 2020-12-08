module Dcv
  class Routes::SearchCompatibility
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options)
      mapper.match '/search', action: 'index', as: 'compatible_search', via: [:get, :post]
    end
  end
end
