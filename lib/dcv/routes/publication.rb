module Dcv
  class Routes::Publication
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options)
      mapper.put 'publish/:id', action: 'update', as: 'publish'
      mapper.delete 'publish/:id', action: 'destroy', as: 'unpublish'
      mapper.get 'publish', action: 'api_info', as: 'publish_api'
    end
  end
end
