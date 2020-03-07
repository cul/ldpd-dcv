module Dcv
  class Routes::Previews
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options)
      mapper.get "/previews/:id", action: 'preview', as: "preview", constraints: { id: /[^\?]+/ }
    end
  end
end
