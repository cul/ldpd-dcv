module SolrDocument::OpenUrlContext
  # The core Blacklight API expectation is only the block, but our components will pass necessary data
  def export_as_openurl_ctx_kev(application_name: nil, id_url: nil, &block)
    application_name ||= eval("application_name", block.binding)
    id_url ||= begin
      id_proc = Proc.new { url_for(:action=>'show', :id => @document, :host => request.host) }
      block.binding.receiver.instance_eval &id_proc
    end
    str_title = title.to_str
    'ctx_ver=Z39.88-2004&amp;' +
    'rft_val_fmt=info:ofi/fmt:kev:mtx:dc&amp;' +
    'rfr_id=info:sid/ocoins.info:generator&amp;' +
    'rft.identifier=' + CGI::escape(id_url) + '&amp;' +
    'rft.title=' + CGI::escape(str_title) + '&amp;' +
    'rft.type=' + CGI::escape('Web Page') + '&amp;' +
    (self['lib_format_ssm'].present? ? ('rft.format=' + CGI::escape(self['lib_format_ssm'].join(', ')) + '&amp;') : '') +
    'rft.source=' + CGI::escape(application_name) + '&amp;' +
    (self['abstract_ssm'].present? ? ('rft.description=' + CGI::escape(self['abstract_ssm'].join(', ')) + '&amp;') : '') +
    (self['lib_date_textual_ssm'].present? ? ('rft.date=' + CGI::escape(self['lib_date_textual_ssm'].join(', ')) + '&amp;') : '') +
    'rft.language=English'
  end
end