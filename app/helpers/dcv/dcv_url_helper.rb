module Dcv::DcvUrlHelper
  def link_to_url_value(args)
    values = args[:document][args[:field]]

    values.map {|value|
      link_to(value, value)
    }
  end

  # args: document, field, config, value
  def render_link_to_external_resource(args = {})
    scalar_value = !(args[:value].is_a? Array)
    link_label = args[:config].link_label || "See also"
    link_label = "#{link_label} <span class=\"glyphicon glyphicon-new-window\"></span>".html_safe
    links = Array(args[:value]).map {|url| link_to(link_label, url, target: '_blank') }
    scalar_value ? links.first : links
  end

  # args: document, field, config, value
  def render_link_to_clio(args = {})
    scalar_value = !(args[:value].is_a? Array)
    clio_links = Array(args[:value]).map do |clio_id|
      link_label = "#{args[:config].link_label || clio_id} <span class=\"glyphicon glyphicon-new-window\"></span>".html_safe
      link_to(link_label, "http://clio.columbia.edu/catalog/#{clio_id}", target: '_blank')
    end
    scalar_value ? clio_links.first : clio_links
  end

  def display_doi_link(args={})
    args.fetch(:value,[]).map do |v|
      v.sub!(/^doi:/,'')
      url = "https://dx.doi.org/#{v}"
      link_to(url, url)
    end
  end

  def url_for_document(doc, options = {})
    doc = SolrDocument.new(doc) unless doc.nil? or doc.is_a? SolrDocument
    if doc.is_a?(SolrDocument) && doc.site_result?
      slug = doc['slug_ssim']
      is_restricted = doc['restriction_ssim'].present? && doc['restriction_ssim'].include?('Onsite')
      is_restricted ? restricted_site_path(slug) : site_path(slug)
    else
      super
    end
  end

  def has_persistent_link?(document)
    document.has_persistent_url?
  end

  # Return the preferred bytestream name:
  # 1. content if the original name matches a pattern in keep_originals
  # 2. access if available
  # 3. content by default
  # @param doc [Hash] SolrDocument
  # @param keep_originals [Array<Regexp>] name patterns to defer to original for
  # @return [String] preferred bytestream name
  def preferred_content_bytestream(doc, *keep_originals)
    doc = SolrDocument.new(doc) unless doc.nil? or doc.is_a? SolrDocument
    if doc.is_a?(SolrDocument)
      originals = doc['original_name_ssim'] || doc[:original_name_ssim] || []
      datastreams = doc['datastreams_ssim'] || doc[:datastreams_ssim] || ['content']
      if originals.detect {|o| keep_originals.detect {|k| k.match(o) } }
        return (['service','content'] & datastreams.map(&:to_s)).first
      end
      return (['access','service','content'] & datastreams.map(&:to_s)).first
    end
    return nil
  end

  def persistent_link_to(label, document, opts = {})
    link_to(label, persistent_url_for(document), opts)
  end

  def persistent_url_for(document)
    document.persistent_url
  end

  def local_blank_search_url
    return url_for({controller: controller_name, action: 'index', search_field: 'all_text_teim', q: '' })
  end

  def local_image_search_url
    return url_for({controller: controller_name, action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'lib_format_sim' => (durst_format_list.keys.reject{|key| key == 'books'})}})
  end

  def local_facet_search_url(facet_field_name, value)
    return url_for({controller: controller_name, action: 'index', search_field: 'all_text_teim', q: '', 'f' => {facet_field_name => [value]}})
  end

  def local_subject_search_url(subject_term_value)
    return url_for({controller: controller_name, action: 'index', search_field: 'all_text_teim', q: '', 'f' => {'durst_subjects_ssim' => [subject_term_value]}})
  end

  def landing_page_search_url(document)
    return nil unless document[:short_title_ssim].present?
    search_scope = document.fetch('search_scope_ssi', "project") || "project"
    facet_field = (search_scope == 'collection') ? 'lib_collection_sim' : 'lib_project_short_ssim'
    facet_value = document.fetch('short_title_ssim',[]).first
    if document[:restriction_ssim].present?
      repository_id = document[:lib_repo_code_ssim].first
      search_repository_catalog_path(repository_id: repository_id, f: {facet_field => [facet_value]})
    else
      search_action_path(:f => {facet_field => [facet_value]})
    end
  end

  def terms_of_use_url
    'https://library.columbia.edu/resolve/lweb0208'
  end

  def site_edit_link(sep: ' | ')
    return unless (@subsite && can?(:update, @subsite))
    if @page && (@page.slug.to_s != 'home')
      edit_href = edit_site_page_path(site_slug: @subsite.slug, slug: @page.slug)
    else
      edit_href = edit_site_path(slug: @subsite.slug)
    end
    edit_ele = link_to(edit_href) do
      "<span class=\"glyphicon glyphicon-pencil\"></span> Edit".html_safe
    end
    "#{sep}#{edit_ele}".html_safe
  end

# solr_document routing patches to get BL6 up and running
# TODO remove these
  def solr_document_path(solr_document)
    if controller.is_a?(SitesController) and !solr_document.site_result?
      # TODO: refactor after local site searches are implemented
      url_for(params.merge(action: 'show', id: solr_document, controller: 'catalog', slug: nil))
    else
      url_for(params.merge(action: 'show', id: solr_document))
    end
  end

# solr_document routing patches to get BL6 up and running
# TODO remove these
  def solr_document_url(solr_document, options = {})
    search_state.url_for_document(solr_document, options)
  end
end
