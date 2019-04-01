module ActionDispatch::Routing
  class Mapper
    # example
    #   subsite_for :catalog
    #   subsite_for :catalog, :durst
    #   subsite_for :catalog, except: [ :saved_searches ]
    #   subsite_for :catalog, only: [ :saved_searches, :solr_document ]
    #   subsite_for :catalog, constraints: {id: /[0-9]+/ }
    def subsite_for(*resources)
      options = resources.extract_options!
      resources.map!(&:to_sym)
      Dcv::Routes.new(self, options.merge(resources: resources)).draw
    end
  end
end