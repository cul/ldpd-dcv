module Dcv
  class Routes::RequestTracking
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, options = {})
      options = @defaults.merge(options).merge(only: [:show], format: 'html', prefix: '')
      #options = { only: [:show], format: 'html' }
      mapper.resources(:solr_document, options) do
        mapper.member do
          mapper.post "track"
        end
      end
    end
  end
end
