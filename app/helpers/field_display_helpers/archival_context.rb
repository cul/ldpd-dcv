module FieldDisplayHelpers::ArchivalContext
  def has_archival_context?(field_config, document)
    SolrDocument.wrap(document).has_archival_context?(field_config.archival_context_field || field_config.field)
  end

  def display_archival_context(args={})
    shelf_locator = field_helper_shelf_locator_value(args) if args.fetch(:shelf_locator, true)
    document = args[:document]
    aspace_ids = document&.fetch(FieldDisplayHelpers::ASPACE_PARENT_FIELD, nil)
    document.archival_contexts.map do |context|
      context.aspace_id = aspace_ids&.first
      title = context.titles(link: args.fetch(:link, true)).first.dup
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
        context_label = display_archival_context(args.merge(field: context_field.field, value: document[context_field.field], link: false))
        "#{value}. #{context_label}"
      end
    end
    args[:value].is_a?(Array) ? values : values[0]
  end

  def display_collection_with_links(args={})
    values = Array(args[:value])
    document = args[:document]
    if document.has_archival_context? || document.has_collection_bib_links?
      json = document.archival_context_json
      values.map do |value|
        collection = json.detect { |context| context['dc:title'].to_s.strip == value.strip }
        if collection
          clio = collection.fetch('dc:bibliographicCitation',{})['@id']
          if clio
            bib_id = clio.split('/')[-1].to_s
            # Voyager BIBs will be all numeric; FOLIO BIBs will be prefixed for 'instance'
            if bib_id =~ /^(in)?\d+$/
              clio_only = collection.fetch('dc:coverage', []).blank?
              fa_url = document.finding_aid_url(bib_id, clio_only: clio_only)
              value = link_to(value, fa_url) if fa_url
            end
          end
        end
        value.html_safe
      end
    else
      values
    end
  end

  def has_collection_bib_links?(field_config, document)
    document.has_collection_bib_links?
  end

  def display_collection_bib_links(args={})
    document = args[:document]
    document.collection_bib_links.map do |clio|
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
