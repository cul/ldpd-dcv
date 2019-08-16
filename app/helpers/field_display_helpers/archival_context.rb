module FieldDisplayHelpers::ArchivalContext
  def has_archival_context?(field_config, document)
    json_src = document.fetch(field_config.field,'{}')
    JSON.load(json_src).detect {|ac| ac['dc:coverage'].present? }
  end

  def display_archival_context(args={})
    contexts = JSON.load(args.fetch(:value,'[]')).map { |json| ::ArchivalContext.new(json) }

    shelf_locator = field_helper_shelf_locator_value(args)
    contexts.map do |context|
      title = context.titles(link: args.fetch(:link, true)).first
      title << '. ' << shelf_locator if shelf_locator && title.present?
      title
    end.join('; ').html_safe
  end

  def display_composite_archival_context(args={})
    values = Array(args[:value])
    document = args[:document]
    context_field = OpenStruct.new(field: 'archival_context_json_ss')
    if has_archival_context?(context_field, document)
      values = values.map do |value|
        value << '. '
        value << display_archival_context(args.merge(field: context_field.field, value: document[context_field.field], link: false))
        value
      end
    end
    args[:value].is_a?(Array) ? values : values[0]
  end

  def display_collection_with_links(args={})
    values = Array(args[:value])
    document = args[:document]
    if document['archival_context_json_ss']
      json = JSON.load(document['archival_context_json_ss'])
      values.map do |value|
        collection = json.detect { |context| context['dc:title'].to_s.strip == value.strip }
        if collection
          clio = collection.fetch('dc:bibliographicCitation',{})['@id']
          if clio
            bib_id = clio.split('/')[-1]
            fa_url = generate_finding_aid_url(bib_id, document)
            value = link_to(value, fa_url) if fa_url
          end
        end
        value.html_safe
      end
    else
      args[:value]
    end
  end

  def has_collection_bib_links?(field_config, document)
    if document['archival_context_json_ss']
      JSON.load(document['archival_context_json_ss']).detect do |collection|
        collection['dc:bibliographicCitation']
      end
    end
  end

  def display_collection_bib_links(args={})
    document = args[:document]
    JSON.load(document['archival_context_json_ss']).select do |collection|
      collection['dc:bibliographicCitation']
    end.map do |collection|
      clio = collection.fetch('dc:bibliographicCitation',{})['@id']
      link_to(clio, clio) if clio
    end
  end

  def field_helper_shelf_locator_value(args = {})
    document = args[:document]
    return unless document.present?
    shelf_locator = document['location_shelf_locator_ssm']
    shelf_locator.present? ? shelf_locator.first : nil
  end
end
