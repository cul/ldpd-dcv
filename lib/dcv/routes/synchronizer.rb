module Dcv
  class Routes::Synchronizer
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options)
      mapper.get "/:id/synchronizer", action: 'synchronizer', as: "synchronizer", constraints: { id: /[^\?]+/ }
    end
  end
end
