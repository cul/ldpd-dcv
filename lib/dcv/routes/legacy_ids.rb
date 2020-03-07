module Dcv
  class Routes::LegacyIds
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options)
      mapper.get "legacy_redirect", action: 'legacy_redirect', as: "legacy_redirect"
    end
  end
end
