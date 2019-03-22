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
end
