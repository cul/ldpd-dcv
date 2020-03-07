module Dcv
  class Routes::NodeProxies
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options)
      mapper.get "/:id/proxies(/*proxy_id)", action: "proxies", as: "proxies".to_sym, constraints: { proxy_id: /[^\?]+/ }
    end
  end
end
