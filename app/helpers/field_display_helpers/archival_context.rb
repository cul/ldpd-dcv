module FieldDisplayHelpers::ArchivalContext
  def has_archival_context?(field_config, document)
    json_src = document.fetch(field_config.archival_context_field || field_config.field,'{}')
    JSON.load(json_src).detect {|ac| ac['dc:coverage'].present? }
  end

  def display_archival_context(args={})
    contexts = Array(args.fetch(:value,'[]')).map { |json_values| JSON.load(json_values).map {|json| ::ArchivalContext.new(json) } }
    contexts.flatten!
    shelf_locator = field_helper_shelf_locator_value(args) if args.fetch(:shelf_locator, true)
    document = args[:document]
    aspace_ids = document&.fetch(FieldDisplayHelpers::ASPACE_PARENT_FIELD, nil)
    contexts.map do |context|
      context.aspace_id = aspace_ids&.first
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
            bib_id = clio.split('/')[-1].to_s
            if bib_id =~ /^\d+$/
              clio_only = collection.fetch('dc:coverage', []).blank?
              fa_url = generate_finding_aid_url(bib_id, document, clio_only: clio_only)
              value = link_to(value, fa_url) if fa_url
            end
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

  def has_sublocation_information?(field_config, document)
    ['lib_sublocation_ssm', 'lib_collection_ssm', 'location_shelf_locator_ssm'].detect { |f| document[f].present? }
  end

  # Example output: "Avery Classics Collection, Seymour B. Durst Old York Library Collection, Box no. 35, Item no. 353."
  def display_sublocation_information(args = {})
    document = args[:document]
    info = []
    if document['lib_sublocation_ssm'].present?
      info << document['lib_sublocation_ssm'][0]
      url = ActiveSupport::HashWithIndifferentAccess.new(I18n.t('ldpd.url.sublocation'))[info[-1]]
      if url
        info[-1] = link_to(info[-1], url)
      end
    end
    info << document['lib_collection_ssm'][0] if document['lib_collection_ssm'].present?
    info << document['location_shelf_locator_ssm'][0] if document['location_shelf_locator_ssm'].present?
    info[-1] = info[-1] + '.' if info[-1]
    return info.join(', ').html_safe if info.present?
  end
end
