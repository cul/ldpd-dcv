module Dcv::Catalog::CitationDisplayBehavior
  extend ActiveSupport::Concern

  VALID_CITATION_TYPES = {
    'apa' => 'APA',
    'chicago' => 'Chicago',
    'mla' => 'MLA'
  }

  def citation

    id = params[:id]
    type = VALID_CITATION_TYPES.has_key?(params[:type]) ? params[:type] : nil

    if type.blank?
      render text: 'Please specify a valid citation type.  One of: ' + VALID_CITATION_TYPES.keys.join(', ')
    else

      #TODO: Get data for item
      @response, @document = get_solr_response_for_doc_id(id)

      @citation_type_label = VALID_CITATION_TYPES[type]

      names_string = @document['lib_name_ssm'] ? @document['lib_name_ssm'].join(', ') : nil
      title_string = @document['title_display_ssm'] ? @document['title_display_ssm'].join(' ') : nil
      textual_date_string = @document['lib_date_textual_ssm'] ? @document['lib_date_textual_ssm'].join(' ') : nil
      format_singular_string = @document['lib_format_ssm'] ? @document['lib_format_ssm'].join(' ').capitalize.singularize : nil
      collection_string = @document['lib_collection_ssm'] ? @document['lib_collection_ssm'].join(' ') : nil
      repository_string = @document['lib_repo_full_ssim'] ? @document['ib_repo_full_ssim'].join(' ') : nil
      application_name_string = t('blacklight.application_name')
      today_date_string = Time.now.strftime("%d %b %Y")
      item_url_string = url_for({:action => 'show', :id => id})

      @citation_text = ''

      if type == 'apa'

        @citation_text += ensure_ends_with_period!(names_string) + ' ' if names_string.present?
        @citation_text += "(#{textual_date_string}). " if textual_date_string.present?
        @citation_text += "#{title_string}. " if title_string.present?
        @citation_text += "<em>#{application_name_string} [Columbia University Libraries]</em>. "
        @citation_text += "[#{format_singular_string}]. " if format_singular_string.present?
        @citation_text += "Retrieved from #{item_url_string}"

      elsif type == 'chicago' # DONE!

        @citation_text += ensure_ends_with_period!(names_string) + ' ' if names_string.present?
        @citation_text += "\"#{title_string}.\" " if title_string.present?
        @citation_text += "#{format_singular_string}. " if format_singular_string.present?
        @citation_text += "#{textual_date_string}. " if textual_date_string.present?
        @citation_text += "<em>#{application_name_string} [Columbia University Libraries]</em>. Accessed #{today_date_string}. "
        @citation_text += item_url_string

      elsif type == 'mla' # DONE!

        @citation_text += ensure_ends_with_period!(names_string) + ' ' if names_string.present?
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

      render layout: 'empty'
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
