module Dcv
  class Routes::SiteShowable
    DOI_ID_CONSTRAINT = { id: /10\.[A-Za-z0-9\-]+\/[^\/]+/ }
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options)

      mapper.get "/*id", controller: 'search', action: 'show', constraints: DOI_ID_CONSTRAINT
      # track is implemented in Blacklight and can use whatever the internal id is
      mapper.post "/:id/track", controller: 'search', action: 'track', as: 'track'
      mapper.get "/*id/synchronizer", controller: 'search', action: 'synchronizer', as: "synchronizer", constraints: DOI_ID_CONSTRAINT
      mapper.get "/previews/*id", controller: 'search', action: 'preview', as: "preview", constraints: DOI_ID_CONSTRAINT
    end
  end
end
