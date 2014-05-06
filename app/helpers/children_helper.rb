module ChildrenHelper
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::ConfigurationHelperBehavior
  def children(id=params[:id], opts={})
    # get the document
    @response, @document = get_solr_response_for_doc_id(id)
    # get the model class
    klass = @document['active_fedora_model_ssi'].constantize
    # get a relation for :parts
    reflection = klass.reflect_on_association(:parts)
    association = reflection.association_class.new(IdProxy.new(id), reflection)
    children = []
    fl = ['id']
    title_field = nil
    begin
      fl << (title_field = document_show_link_field).to_s
    rescue
    end
    opts = {fl: fl.join(',')}.merge(opts)
    association.load_from_solr(opts).map do |doc|
      child = {id: doc['id'], thumbnail: thumb_url(doc['id'])}
      if title_field
        title = doc[title_field.to_s]
        title = title.first if title.is_a? Array
        child[:title] = title
      end
      children << child
    end
    children
  end

  #TODO: replace this with Cul::Scv::Fedora::FakeObject
  class IdProxy
    attr_reader :id
    def initialize(id)
      @id = id
    end

    def internal_uri
      @uri ||= "info:fedora/#{@id}"
    end

    def new_record?
      false
    end
  end
end