module Dcv
  class Routes::SiteShowable
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options)

      mapper.get "/legacy_redirect", controller: 'search', action: 'legacy_redirect'

      mapper.get "/*id", controller: 'search', action: 'show', constraints: Dcv::Routes::DOI_ID_CONSTRAINT
      mapper.get "/:id", controller: 'search', action: 'show', constraints: Dcv::Routes::LEGACY_ID_CONSTRAINT

      # track is implemented in Blacklight and can use whatever the internal id is
      mapper.post "/:id/track", controller: 'search', action: 'track', as: 'track'
      mapper.get "/*id/synchronizer", controller: 'search', action: 'synchronizer', as: "synchronizer", constraints: Dcv::Routes::DOI_ID_CONSTRAINT
      mapper.get "/previews/*id", controller: 'search', action: 'preview', as: "preview", constraints: Dcv::Routes::DOI_ID_CONSTRAINT
    end
  end
end
