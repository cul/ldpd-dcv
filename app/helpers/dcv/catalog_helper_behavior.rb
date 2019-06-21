module Dcv::CatalogHelperBehavior

  def url_for_children_data(per_page=nil)
    opts = {id: params[:id], controller: :children}
    opts[:per_page] = per_page || 4
    opts[:protocol] = (request.ssl?) ? 'https' : 'http'
    url_for(opts)
  end

  def format_value_transformer(value)
    transformation = {'resource' => 'File Asset', 'multipartitem' => 'Item', 'collection' => 'Collection'}
    if transformation.has_key?(value)
      return transformation[value]
    else
      return value
    end
  end

  def publisher_transformer(value)

    transformation = Rails.cache.fetch('dcv.publisher_ssim_to_short_title', expires_in: 10.minutes) do
      map = {}
      Blacklight.solr.tap do |rsolr|
        solr_params = {
          qt: 'search',
          rows: 10000,
          fl: 'id,title_display_ssm,short_title_ssim',
          fq: ["dc_type_sim:\"Publish Target\"","active_fedora_model_ssi:Concept"],
          facet: false
        }
        response = rsolr.get 'select', :params => solr_params
        docs = response['response']['docs']
        docs.each do |doc|
          short_title = doc['short_title_ssim'] || doc['title_display_ssm']
          map["info:fedora/#{doc['id']}"] = short_title.first if short_title.present?
        end
      end

      map
    end

    if transformation.has_key?(value)
      return transformation[value]
    else
      return value
    end
  end

  def parents(document=@document, extra_params={})
    fname = 'cul_member_of_ssim' #solr_name(:cul_member_of, :symbol)
    p_pids = Array.new(document[fname])
    p_pids.compact!
    p_pids.collect! {|p_pid| p_pid.split('/')[-1].sub(':','\:')}
    controller.get_solr_response_for_document_ids(p_pids, extra_params)[1]
  end

  def link_to_resource_in_context(document=@document)
    parents = parents(document)
    parents.collect do |parent|
      link_to(parent.fetch('title_display_ssm',[]).first, catalog_url(id:parent['id']))
    end
  end

  ##
  # Link to the previous document in the current search context
  def button_to_previous_document(previous_document, opts={})
    link_opts = session_tracking_params(previous_document, search_session['counter'].to_i - 1).merge(:class => "previous", :rel => 'prev')
    # raw(t('views.pagination.previous'))
    link_opts.merge!(opts)
    link_to_unless previous_document.nil?, '<i class="glyphicon glyphicon-arrow-left"></i>'.html_safe, url_for_document(previous_document), link_opts do
      if opts[:class]
        opts = opts.merge(class: opts[:class] + ' disabled')
      else
        opts = opts.merge(class: 'disabled')
      end
      content_tag :button, opts do
        content_tag :i, '', :class => 'glyphicon glyphicon-arrow-left'
      end
    end
  end

  ##
  # Link to the next document in the current search context
  def button_to_next_document(next_document, opts={})
    link_opts = session_tracking_params(next_document, search_session['counter'].to_i + 1).merge(:class => "next", :rel => 'next')
    # raw(t('views.pagination.next'))
    link_opts.merge!(opts)
    link_to_unless next_document.nil?, '<i class="glyphicon glyphicon-arrow-right"></i>'.html_safe, url_for_document(next_document), link_opts do
      if opts[:class]
        opts = opts.merge(class: opts[:class] + ' disabled')
      else
        opts = opts.merge(class: 'disabled')
      end
      content_tag :button, opts do
        content_tag :i, '', :class => 'glyphicon glyphicon-arrow-right'
      end
    end
  end

  def pcdm_file_genre_display value
    t("pcdm.file_genre.#{value}")
  end

  def total_dcv_asset_count
    Rails.cache.fetch('total_dcv_asset_count', expires_in: 12.hours) do
      solr_params = {
        qt: 'search',
        rows: 0,
        fq: ["active_fedora_model_ssi:GenericResource"],
        facet: false
      }
      response = Blacklight.solr.get 'select', :params => solr_params
      response['response']['numFound'].to_i
    end
  end

  def rounded_down_and_formatted_dcv_asset_count
    round_to_nearest = 5000 # e.g. round 12,345 down to nearest 5000: 10,000
    exact_total = total_dcv_asset_count
    return exact_total if exact_total < round_to_nearest

    count_to_return = exact_total / round_to_nearest * round_to_nearest
    number_with_delimiter(count_to_return.round(-3), :delimiter => ',')
  end

  def solr_url_hash(document, opts = {})
    candidates = JSON.parse(document.fetch(:location_url_json_ss, "[]"))
    exclude = opts.fetch(:exclude, {})
    candidates.select do |c|
      !c.detect { |k,v| exclude[k] == v }
    end
  end

  # Scrub permanent links from catalog data to use modern resolver syntax
  # @param perma_link [String] the original link
  # @return [String] link with cgi version of resolver replaced with modern version
  def clean_resolver(link_src)
    if link_src
      link_uri = URI(link_src)
      if link_uri.path == "/cgi-bin/cul/resolve" && link_uri.host == "www.columbia.edu"
        return "https://library.columbia.edu/resolve/#{link_uri.query}"
      end
    end
    link_src
  end
  # Does this document represent an object with synchronized media?
  # @param document [Hash] the representative document
  # @return [Boolean]
  def has_synchronized_media?(document)
    (document.fetch(:datastreams_ssim, []) & ['chapters','captions']).present?
  end

  # Pull indexable names, hash to roles
  def display_names_with_roles(args={})
    document = args.fetch(:document,{})
    exclusions = args.fetch(:exclusions, []).map(&:capitalize)
    names = args.fetch(:value,[]).map {|name| [name,[]]}.to_h
    document.each do |f,v|
      next unless f =~ /role_.*_ssim/
      role = f.split('_')
      role.shift
      role.pop
      role = role[0].present? ? role.join(' ') : nil
      v.each { |name| names[name] << role.capitalize if role && names[name] }
    end
    field = args[:field]
    field_config = (controller.action_name.to_sym == :index) ?
      blacklight_config.index_fields[args[:field]] :
      blacklight_config.show_fields[args[:field]]
    names.map do |name, roles|
      value = field_config.link_to_search ?
        link_to(name, controller.url_for(action: :index, f: { field_config.link_to_search => [name] })) :
        name.dup
      value << " (#{roles.join(',')})" unless roles.empty?
      value.html_safe 
      value if roles.empty? or roles.detect { |role| !exclusions.include?(role) }
    end.compact
  end

  def display_clio_link(args={})
    args.fetch(:value,[]).map { |v| v.sub!(/^clio/i,''); link_to("https://clio.columbia.edu/catalog/#{v}", "https://clio.columbia.edu/catalog/#{v}") }
  end

  def display_doi_link(args={})
    args.fetch(:value,[]).map do |v|
      v.sub!(/^doi:/,'')
      url = "https://dx.doi.org/#{v}"
      link_to(url, url)
    end
  end

  def has_archival_context?(field_config, document)
    json_src = document.fetch(field_config.field,'{}')
    JSON.load(json_src).detect {|ac| ac['dc:coverage'].present? }
  end

  def display_archival_context(args={})
    contexts = JSON.load(args.fetch(:value,'[]')).map { |json| ArchivalContext.new(json) }

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
        collection = json.detect {|context| context['dc:title'] == value}
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

  def field_helper_shelf_locator_value(args = {})
    document = args[:document]
    return unless document.present?
    shelf_locator = document['location_shelf_locator_ssm']
    shelf_locator.present? ? shelf_locator.first : nil
  end

  def field_helper_repo_code_value(args = {})
    document = args[:document]
    return unless document.present?
    document['repo_code_lookup'] ||= begin
      repo_fields = ['lib_repo_full_ssim', 'lib_repo_short_ssim']
      repo_code = nil
      repo_fields.detect do |field|
        unless document[field].blank?
          codes = code_map_for_repo_field(field)
          document[field].detect do |repo_value|
            repo_code = codes[repo_value]
          end
        end
      end
      repo_code
    end
  end

  def code_map_for_repo_field(field)
    HashWithIndifferentAccess.new(I18n.t('ldpd.' + field.split('_')[-2] + '.repo').invert)
  end

  def generate_finding_aid_url(bib_id, document)
    repo_fields = ['lib_repo_full_ssim', 'lib_repo_short_ssim']
    repo_code = field_helper_repo_code_value(document: document)
    if repo_code && bib_id
      "https://findingaids.library.columbia.edu/ead/#{repo_code.downcase}/ldpd_#{bib_id}/summary"
    else
      nil
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

  # Look up the label for the generated field
  def render_generated_field_label document, field_config
    field = field_config.field
    label = field_config.label
    if label.is_a? Symbol
      label = send label, document, field_config
    end
    t(:'blacklight.search.show.label', label: label)
  end

  def notes_label(document, opts)
    field = opts[:field]
    type = field.split('_')[1..-3].join(' ').capitalize
    if type.eql?('Untyped')
      "Note"
    else
      "Note (#{type})"
    end
  end

  def is_excepted_dynamic_field?(field_config, document)
    (field_config.except || []).include? field_config.field
  end

  def rightsstatements_label(value)
    Rails.application.config_for(:copyright)[value]
  end

  def display_as_link_to_rightsstatements(args={})
    values = Array(args[:value])
    document = args[:document]
    values.map { |value| link_to(rightsstatements_label(value), value, target: "_new") }
  end
end
