module Dcv::ChildrenHelperBehavior
  def document_children_from_model(opts={})
    # get the model class
    klass = @document['active_fedora_model_ssi'].constantize
    # get a relation for :parts
    reflection = klass.reflect_on_association(:parts)
    association = reflection.association_class.new(IdProxy.new(@document[:id]), reflection)
    children = {parent_id: @document[:id], children: []}
    children[:per_page] = opts.fetch(:per_page, 10).to_i
    children[:page] = opts.fetch(:page, 0).to_i
    offset = children[:per_page] * children[:page]
    rows = children[:per_page]
    fl = ['id',"active_fedora_model_ssi",'dc_identifier_ssim','identifier_ssim','rels_int_profile_tesim','rft_id_ss']
    title_field = nil
    begin
      fl << (title_field = document_show_link_field).to_s
    rescue
    end
    opts = {fl: fl.join(','), raw: true, rows: rows, start: offset}.merge(opts)
    response = association.load_from_solr(opts)['response'];
    children[:pages] = (response['numFound'].to_f / rows).ceil
    children[:page] = children[:page]
    children[:count] = response['numFound'].to_i
    response['docs'].map do |doc|
      children[:children] << child_from_solr(doc)
    end
    children
  end

  def child_from_solr(doc)
    title_field = nil
    begin
      fl << (title_field = document_show_link_field).to_s
    rescue
    end
    opts = {controller: :thumbs, id: doc['id'], action: :show}
    opts[:only_path] = true
    child = {id: doc['id'], thumbnail: url_for(opts)}
    opts[:controller] = :screen_images
    child[:screen] = url_for(opts)
    if title_field
      title = doc[title_field.to_s]
      title = title.first if title.is_a? Array
      child[:title] = title
    end
    if doc["active_fedora_model_ssi"] == 'GenericResource'
      child[:contentids] = doc['dc_identifier_ssim']
      rels_int = JSON.load(doc.fetch('rels_int_profile_tesim',[]).join(''))
      unless rels_int.blank?
        #child[:rels_int] = rels_int
        width = rels_int["info:fedora/#{child[:id]}/content"].fetch('exif_image_width',[0]).first.to_i
        length = rels_int["info:fedora/#{child[:id]}/content"].fetch('exif_image_length',[0]).first.to_i
        child[:width] = width if width > 0
        child[:length] = length if length > 0
      end
      if (base_rft = doc['rft_id_ss'])
        zoom = rels_int["info:fedora/#{child[:id]}/content"].fetch('foaf_zooming',['zoom']).first
        zoom = zoom.split('/')[-1]
        base_rft.sub!(/^info\:fedora\/datastreams/,ActiveFedora.config.credentials[:datastreams_root])
        base_rft = 'file:' + base_rft unless base_rft =~ /(file|https?)\:\//
        child[:rft_id] = CGI.escape(base_rft)
        puts rels_int.inspect
        child[:width] ||= rels_int["info:fedora/#{child[:id]}/#{zoom}"].fetch('exif_image_width',[0]).first.to_i
        child[:length] ||= rels_int["info:fedora/#{child[:id]}/#{zoom}"].fetch('exif_image_length',[0]).first.to_i
      end
    end
    return child
  end
  #TODO: replace this with Cul::Scv::Fedora::FakeObject
  class IdProxy < Cul::Scv::Fedora::DummyObject
    def internal_uri
      @uri ||= "info:fedora/#{@pid}"
    end
  end
end