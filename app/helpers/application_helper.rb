module ApplicationHelper
  def restricted?
    if controller.class.respond_to? :restricted?
      controller.class.restricted?
    else
      action_name.eql? 'restricted'
    end
  end

  def hourly_stats(restricted = false)
    publisher_sites = restricted ? SUBSITES['restricted'] : SUBSITES['public']
    publisher_sites = publisher_sites.select {|k,s| k != 'uri' }
    publisher_uris = publisher_sites.map {|key, site| site['uri']}
    fq = publisher_uris.map {|uri| "filter(publisher_ssim:\"#{uri}\")"}.join(' ')
    expires_in = 1.hour
    Rails.cache.fetch("daily_stats/#{restricted ? "restricted" : "public"}" , expires_in: expires_in) do
      stats_params = {
        rows: 0,
        fl: '', # Don't need to return any fields because we're only using facet data
        qt: 'search',
        sort: 'id asc', # Sort for consistent order if we need to repeat the process mid-way through
        facet: true,
        fq: fq,
        df: 'id',
        :'facet.field' => 'active_fedora_model_ssi',
        :'facet.limit' => -1,
        :'facet.pivot' => 'publisher_ssim,active_fedora_model_ssi'
      }
      solr_response = Blacklight.solr.get 'select', params: stats_params
      stats = { as_of: Date.current, total: {}, available: {} }
      facet = solr_response['facet_counts']['facet_fields']['active_fedora_model_ssi']
      facet.each_slice(2) do |pair|
        stats[:available][:assets] = pair[1] if pair[0] == 'GenericResource'
        stats[:available][:items] = pair[1] if pair[0] == 'ContentAggregator'
      end
      stats_params[:fq] = "publisher_ssim:*"
      solr_response = Blacklight.solr.get 'select', params: stats_params
      facet = solr_response['facet_counts']['facet_fields']['active_fedora_model_ssi']
      facet.each_slice(2) do |pair|
        stats[:total][:assets] = pair[1] if pair[0] == 'GenericResource'
        stats[:total][:items] = pair[1] if pair[0] == 'ContentAggregator'
      end
      stats
    end
  end
end
