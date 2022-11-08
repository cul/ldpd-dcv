module Dcv::Catalog::CitationDisplayBehavior
  extend ActiveSupport::Concern

  VALID_CITATION_TYPES = {
    'apa' => 'APA',
    'chicago' => 'Chicago',
    'mla' => 'MLA'
  }

  def show_citation

    id = params[:id]
    type = VALID_CITATION_TYPES.has_key?(params[:type]) ? params[:type] : nil

    if type.blank?
      render text: 'Please specify a valid citation type.  One of: ' + VALID_CITATION_TYPES.keys.join(', ')
    else

      #TODO: Get data for item
      @response, @document = fetch(id)

      single_name_for_citation = @document['lib_name_ssm'].present? ? @document['lib_name_ssm'][0] : nil

      # If the name ends with a date, attempt to remove the date via regex
      name_regex = /(.+)(,\W\d{1,4}\W*-\W*\d{1,4}.*)/
      # It name matches regex, get first capture group only
      if name_regex =~ single_name_for_citation
        single_name_for_citation = single_name_for_citation.match(name_regex).captures[0]
      end

      title_string = @document['title_display_ssm'] ? @document['title_display_ssm'].join(' ') : nil
      textual_date_string = @document['lib_date_textual_ssm'] ? @document['lib_date_textual_ssm'].join(' ') : nil
      format_singular_string = @document['lib_format_ssm'] ? @document['lib_format_ssm'].join(' ').capitalize.singularize : nil
      collection_string = @document['lib_collection_ssm'] ? @document['lib_collection_ssm'].join(' ') : nil
      repository_string = @document['lib_repo_full_ssim'] ? @document['lib_repo_full_ssim'].join(' ') : nil
      application_name_string = t('blacklight.application_name')
      today_date_string = Time.now.strftime("%d %b %Y")
      item_url_string = @document.persistent_url || url_for({:action => 'show', :id => id})

      @citation_text = ''

      if type == 'apa'

        @citation_text += ensure_ends_with_period!(single_name_for_citation) + ' ' if single_name_for_citation.present?
        @citation_text += "(#{textual_date_string}). " if textual_date_string.present?
        @citation_text += "#{title_string}. " if title_string.present?
        @citation_text += "<em>#{application_name_string} [Columbia University Libraries]</em>. "
        @citation_text += "[#{format_singular_string}]. " if format_singular_string.present?
        @citation_text += "Retrieved from #{item_url_string}"

      elsif type == 'chicago' # DONE!

        @citation_text += ensure_ends_with_period!(single_name_for_citation) + ' ' if single_name_for_citation.present?
        @citation_text += "\"#{title_string}.\" " if title_string.present?
        @citation_text += "#{format_singular_string}. " if format_singular_string.present?
        @citation_text += "#{textual_date_string}. " if textual_date_string.present?
        @citation_text += "<em>#{application_name_string} [Columbia University Libraries]</em>. Accessed #{today_date_string}. "
        @citation_text += item_url_string

      elsif type == 'mla' # DONE!

        @citation_text += ensure_ends_with_period!(single_name_for_citation) + ' ' if single_name_for_citation.present?
        @citation_text += "<em>#{title_string}.</em> " if title_string.present?
        @citation_text += "#{textual_date_string}. " if textual_date_string.present?
        @citation_text += "#{format_singular_string}. " if format_singular_string.present?
        if collection_string.present? && repository_string.present?
          @citation_text += "#{collection_string}, #{repository_string}. "
        elsif collection_string.present?
          @citation_text += "#{collection_string}. "
        elsif repository_string.present?
          @citation_text += "#{repository_string}. "
        end
        @citation_text += "<em>#{application_name_string}</em>. #{today_date_string}"

      end

      @citation_text = @citation_text.html_safe

      render layout: 'empty', template: 'citation'
    end

  end

  private

  def ensure_ends_with_period!(string)
    unless string.end_with?('.')
      string = string + '.'
    end
    return string
  end

end
