module Dcv
  class Routes
    DOI_ID_CONSTRAINT = { id: /10\.[A-Za-z0-9\-]+\/[^\/\.]+/ }
    LEGACY_ID_CONSTRAINT = { id: /(cul|ldpd|ac|donotuse):[^\/\.]+/ }

    attr_reader :subsite_keys

    class_attribute :default_route_sets
    self.default_route_sets = [:publication, :previews, :node_proxies, :synchronizer, :request_tracking]

    def initialize(router, options)
      @router = router # cf add_routes
      @options = options
      @subsite_keys = options.fetch(:resources, [:catalog])
    end

    def draw
      sets = (@options[:only] || default_route_sets) - (@options[:except] || [])
      subsite_keys.each do |subsite_key|
        sets.each do |set|
          send(set, subsite_key)
        end
      end
    end

    def publication(subsite_key)
      add_routes do |options|
        resources subsite_key, only: [:show] do
          collection do
            put 'publish/:id' => "#{subsite_key}#update"
            delete 'publish/:id' => "#{subsite_key}#destroy"
            get 'publish' => "#{subsite_key}#api_info"
            get "legacy_redirect" => "#{subsite_key}#legacy_redirect", as: "#{subsite_key}_legacy_redirect".to_sym
          end
        end
      end
    end

    def previews(subsite_key)
      add_routes do |options|
        get "#{subsite_key}/previews/:id" => "#{subsite_key}#preview", as: "#{subsite_key}_preview", constraints: { id: /[^\?]+/ }
      end
    end

    def node_proxies(subsite_key)
      add_routes do |options|
        get "#{subsite_key}/:id/proxies" => "#{subsite_key}#show", as: "#{subsite_key}_root_proxies".to_sym
        get "#{subsite_key}/:id/proxies/*proxy_id" => "#{subsite_key}#show", as: "#{subsite_key}_proxy".to_sym, constraints: { proxy_id: /[^\?]+/ }
      end
    end

    def synchronizer(subsite_key)
      add_routes do |options|
        get "#{subsite_key}/:id/synchronizer" => "#{subsite_key}#synchronizer", as: "#{subsite_key}_synchronizer".to_sym
      end
    end

    def request_tracking(subsite_key)
      add_routes do |options|
        resources(:solr_document, {only: [:show], path: subsite_key.to_s, controller: subsite_key.to_s, :format => 'html'}) do
          member do
            post "track"
          end
        end
      end
    end

    protected

    def primary_resource
      resources.first
    end

    def add_routes &blk
      @router.instance_exec(@options, &blk)
    end
  end
end