class Iiif::Manifest < Iiif::BaseResource
  attr_reader :route_helper, :solr_document, :children_service, :ability_helper

  def initialize(id:, solr_document:, children_service:, route_helper:, ability_helper:, part_of: nil, **args)
    super(id: id, solr_document: solr_document)
    @children_service = children_service
    @route_helper = route_helper
    @ability_helper = ability_helper
    @part_of = part_of
  end

  def label
    value = @solr_document['title_display_ssm'].present? ? @solr_document['title_display_ssm'][0] : @solr_document.id
    { en: [value] }
  end

  def summary
    value = @solr_document['abstract_ssm'].present? ? @solr_document['abstract_ssm'][0] : nil
    { en: [value] } if value
  end

  def metadata
    # Should this class be a presenter rather than a model?
    fields = []
    presenter = Dcv::ShowPresenter.new(@solr_document, @route_helper.view_context)
    presenter.fields_to_render do |name, field_config, field_presenter|
      field_presenter.except_operations << Blacklight::Rendering::Join
      fields << {
        label: { en: [field_presenter.label]},
        value: { en: Array(field_presenter.render) }
      } unless field_config.iiif == false
    end

    if self.marcorg.present?
      fields << self.marcorg
    end
    if self.archival_collection.present?
      fields << self.archival_collection
    end

    descriptor_values = descriptors
    if descriptor_values.present?
      fields.unshift({
        label: { en: ['Described In'] },
        value: { en: descriptor_values }
      })
    end
    fields
  end

  def homepage
    values = []
    if @solr_document.doi_identifier
      registrant, doi = @solr_document.doi_identifier.split('/')
      more_at_url = route_helper.resolve_doi_url(registrant: registrant, doi: doi)
      values.unshift({
        id: more_at_url,
        format: "text/html",
        label: { en: [t('blacklight.application_name')] },
        language: ["en"],
        type: @solr_document['dc_type_ssm']&.first || "Text",
      })
    elsif @solr_document.persistent_url
      values.unshift({
        id: @solr_document.persistent_url,
        format: "text/html",
        label: { en: ['More At'] },
        language: ["en"],
        type: @solr_document['dc_type_ssm']&.first || "Text",
        value: { en: ["<a href=\"#{@solr_document.persistent_url}\" target=\"_blank\" rel=\"nofollow, noindex, noreferrer\">#{t("blacklight.application_name")}</a>"] }
      })
    end
    values
  end

  def descriptors
    memberships = Array(@solr_document['cul_member_of_ssim'])
    if memberships.length > 1
      fq = [
        "fedora_pid_uri_ssi:(\"#{memberships.join("\" OR \"")}\")",
        "active_fedora_model_ssi:ContentAggregator"
      ]
      resp, docs = children_service.searcher.search_results({}) do |params|
        params.merge(fq: fq, facet: false)
      end
      docs.select {|doc| doc.persistent_url}.map do |doc|
        label = doc['title_display_ssm']&.first || doc['dc_title_ssm']&.first || doc.persistent_url
        "<a href=\"#{doc.persistent_url}\" target=\"_blank\" rel=\"nofollow, noindex, noreferrer\">#{label}</a>"
      end
    end
  end

  def thumbnail
    # TODO: cdn_helper thumbnail_method has placeholder behaviors that would be useful for non-image items
    thumbnail_id = @solr_document.schema_image_identifier || @solr_document.id
    return unless thumbnail_id
    iiif_id = Dcv::Utils::CdnUtils.info_url(id: thumbnail_id).sub(/\/info.json$/,'')
    {
      id: Dcv::Utils::CdnUtils.asset_url(id: thumbnail_id, size: 256, base_type: 'featured', type: 'full', format: 'jpg'),
      type: 'Image',
      format: 'image/jpeg',
      service: [
        {
        "id": iiif_id,
        "type": "ImageService3",
        "profile": "level2"
        }
      ]
    }
  end

  def as_json(opts = {})
    manifest = IIIF_TEMPLATES['manifest'].deep_dup
    manifest.delete("@context") unless opts[:include]&.include?(:context)
    manifest['id'] = @id
    manifest['type'] = 'Manifest'
    manifest['doi'] = doi_property if doi
    manifest['label'] = label
    manifest['provider'].first&.tap do |provider|
      provider['id'] = @id.split('/')[0..2].join('/')
      provider['label'] = { en: [I18n.t('blacklight.application_name')] }
    end
    manifest['homepage'] = homepage
    # Items
    manifest["items"] = items if opts[:include]&.include?(:items)

    if opts[:include]&.include?(:metadata)
      manifest['summary'] = summary
      manifest['metadata'] = metadata
      manifest["behavior"] = behaviors(items)
      manifest["viewingDirection"] = viewing_direction
      manifest['rights'] = @solr_document['copyright_statement_ssi'] if @solr_document['copyright_statement_ssi'].present?
      if @solr_document['lib_acknowledgment_notes_ssm'].present?
        manifest['requiredStatement'] = {
          label: { en: ['Acknowledgment'] },
          value: { en: Array(@solr_document['lib_acknowledgment_notes_ssm']) }
        }
      end
      if @solr_document['fedora_pid_uri_ssi']
        (manifest["rendering"] ||= []) << {
          "id": route_helper.item_mods_url(id: @solr_document.id, format: 'xml'),
          "type": "Dataset",
          "label": { "en": [ "Bibliographic Description in MODS XML" ] },
          "format": "text/xml",
          "schema": "http://www.loc.gov/mods/v3",
          "profile": "https://example.org/profiles/bibliographic"
        }
      end
      if self.archival_collection.present? && self.archival_collection[:seeAlso]&.first
        (manifest["seeAlso"] ||= []) << self.archival_collection[:seeAlso].first.merge({
          "type": "Text",
          "label": { "en": [ "Finding Aid" ] },
          "format": "text/html",
          "profile": self.archival_collection[:profile]
        })
      end
    end
    manifest['thumbnail'] = [thumbnail]
    manifest['partOf'] = Array(@part_of).map {|part| part.as_json } if @part_of.present?
    # TODO: logo
    # TODO: provider from location data
    # TODO: homepage from preferred Site

    manifest.compact
  end

  def items
    return [] unless @solr_document

    if @solr_document['active_fedora_model_ssi'] == 'GenericResource'
      return [canvas_for(@solr_document, route_helper, routing_opts, label[:en]).to_h]
    end

    if @solr_document.has_structure?
      return children_service.from_all_structure_proxies(@solr_document).map do |canvas_document|
        canvas_for(canvas_document, route_helper, routing_opts).to_h
      end.compact
    end

    children_service.from_unordered_membership(@solr_document).map do |canvas_document|
      canvas_for(canvas_document, route_helper, routing_opts).to_h
    end.compact
  end

  def routing_opts
    registrant, doi = solr_document.doi_identifier&.split('/')
    { manifest_registrant: registrant, manifest_doi: doi }
  end

  # valid manifest behavior values:
  # unordered
  # individuals
  # paged
  # continuous
  def behaviors(items = nil)
    return nil if @solr_document['active_fedora_model_ssi'] == 'GenericResource' 
    return [Iiif::Behavior::V3::UNORDERED] unless @solr_document.has_structure?

    num_canvases = items&.length || @solr_document['cul_number_of_members_isi']
    return [Iiif::Behavior::V3::INDIVIDUALS] if num_canvases.nil? || num_canvases < 2

    return Array(@solr_document['iiif_behavior_ssim']) if @solr_document['iiif_behavior_ssim'].present?
    [Iiif::Behavior::V3::INDIVIDUALS]
  end

  def viewing_direction
    return nil if @solr_document['active_fedora_model_ssi'] == 'GenericResource' 
    return @solr_document['iiif_viewing_direction_ssi'] if @solr_document['viewing_direction_ssi'].present?
    Iiif::ViewingDirection::V3::LEFT_TO_RIGHT
  end

  def canvas_for(canvas_document, route_helper, routing_opts, label = nil)
    registrant, doi = canvas_document.doi_identifier&.split('/')
    return unless doi
    canvas_routing_opts = routing_opts.merge(registrant: registrant, doi: doi)
    Iiif::Canvas.new(
      id: route_helper.iiif_canvas_url(canvas_routing_opts), solr_document: canvas_document,
      route_helper: route_helper, label: label, ability_helper: ability_helper, **routing_opts
    )
  end
end