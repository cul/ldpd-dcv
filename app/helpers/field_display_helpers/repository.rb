module FieldDisplayHelpers::Repository
  def field_helper_repo_code_value(args = {})
    document = args.fetch(:document, {}).to_h.with_indifferent_access
    return unless document.present?
    document['repo_code_lookup'] ||= begin
      repo_code = document['lib_repo_code_ssim']&.first
      repo_fields = ['lib_repo_full_ssim', 'lib_repo_short_ssim']
      repo_fields.detect do |field|
        unless document[field].blank?
          codes = code_map_for_repo_field(field)
          document[field].detect do |repo_value|
            repo_code ||= codes[repo_value]
          end
        end
      end
      repo_code
    end
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

  # Link to a translated lib_repo_short_ssim value
  # as a library location URL, if available
  def link_to_repo_homepage(repo_value, code=false)
    url = code ? HashWithIndifferentAccess.new(I18n.t('ldpd.url.repo'))[repo_value] : get_short_repo_names_to_urls[repo_value]
    return unless url
    label = code ? HashWithIndifferentAccess.new(I18n.t('ldpd.full.repo'))[repo_value] : get_short_repo_names_to_full_repo_names.fetch(repo_value, repo_value)
    link_to(label, url)
  end

  def show_field_repository_to_facet_link(args)

    facet_field_name = :lib_repo_short_ssim
    full_repo_names_to_short_repo_names = get_full_repo_names_to_short_repo_names()

    display_values = args[:document][args[:field]]

    display_values.map {|display_value|
      facet_value = display_value # by default
      if full_repo_names_to_short_repo_names.has_key?(display_value)
        facet_value = full_repo_names_to_short_repo_names[display_value]
      end

      url_for_facet_search = search_action_path(:f => {facet_field_name => [facet_value]})

      if display_value == 'Non-Columbia Location' && args[:document]['lib_repo_text_ssm'].present?
        return (args[:document]['lib_repo_text_ssm'].first + '<br />' + link_to("(#{display_value})", url_for_facet_search)).html_safe
      else
        repo_code = field_helper_repo_code_value(args)
        src = [link_to_repo_homepage(repo_code, true)]
        src << '<em>' +
              link_to("Browse Location’s Digital Content",
                      url_for_facet_search) + '</em>'
        src.compact.join('<br />').html_safe
      end
    }
  end

  def show_repository_to_web_link(args)

    facet_field_name = args[:field]
    codes_lookup = HashWithIndifferentAccess.new(I18n.t('ldpd.' + facet_field_name.split('_')[-2] + '.repo').invert)

    repo_names = args[:document][args[:field]]

    repo_names.map do |repo_name|
      if codes_lookup.has_key?(repo_name)
        code = codes_lookup[repo_name]
        web_url = I18n.t("ldpd.url.repo.#{code}") if code
      end

      if web_url
        link_to(repo_name, web_url, target: "_new")
      else
        repo_name
      end
    end
  end

  def show_translated_repository_label(args)
    values = args[:document][args[:field]]
    repo_codes = args[:document]['lib_repo_code_ssim']
    if repo_codes
      values = repo_codes.map { |repo_code| t("cul.archives.display_value.#{repo_code}", default: repo_code) }
    end
    field_config = (controller.action_name.to_sym == :index) ?
      blacklight_config.index_fields[args[:field]] :
      blacklight_config.show_fields[args[:field]]
    separator = field_config[:separator] || '; '
    Array(values).compact.join(separator)
  end

  def show_repository_location_with_contact(args)
    repo_code = field_helper_repo_code_value(args)
    repo_display = t("cul.archives.physical_location.#{repo_code}", default: nil)
    return unless repo_display
    email_display = t("cul.archives.contact_email.#{repo_code}", default: nil)
    if args[:mixed_content]
      message = "Additional content may be accessible in the reading room of the #{repo_display}. Please make arrangements in advance of your visit."
    else
      message = "This item is accessible in the reading room of the #{repo_display}. Please make arrangements in advance of your visit."
    end
    if email_display
      message << " Contact #{link_to(email_display, "mailto:#{email_display}")}."
    end
    message.html_safe
  end

  def code_map_for_repo_field(field)
    HashWithIndifferentAccess.new(I18n.t('ldpd.' + field.split('_')[-2] + '.repo').invert)
  end

  def get_short_repo_names_to_full_repo_names
    short_repo_names_to_marc_codes = HashWithIndifferentAccess.new(I18n.t('ldpd.short.repo').invert)
    marc_codes_to_full_repo_names = HashWithIndifferentAccess.new(I18n.t('ldpd.full.repo'))

    new_hash = {}

    short_repo_names_to_marc_codes.each {|key, value|
      new_hash[key] = marc_codes_to_full_repo_names[value]
    }

    return new_hash
  end

  def get_short_repo_names_to_urls
    short_repo_names_to_marc_codes = HashWithIndifferentAccess.new(I18n.t('ldpd.short.repo').invert)
    marc_codes_to_urls = HashWithIndifferentAccess.new(I18n.t('ldpd.url.repo'))

    new_hash = {}

    short_repo_names_to_marc_codes.each {|key, value|
      new_hash[key] = marc_codes_to_urls[value]
    }

    return new_hash
  end

  def get_full_repo_names_to_short_repo_names
    full_repo_names_to_marc_codes = HashWithIndifferentAccess.new(I18n.t('ldpd.full.repo').invert)
    marc_codes_to_short_repo_names = HashWithIndifferentAccess.new(I18n.t('ldpd.short.repo'))

    new_hash = {}

    full_repo_names_to_marc_codes.each {|key, value|
      new_hash[key] = marc_codes_to_short_repo_names[value]
    }

    return new_hash
  end

  def get_long_repo_names_to_short_repo_names
    full_repo_names_to_marc_codes = HashWithIndifferentAccess.new(I18n.t('ldpd.long.repo').invert)
    marc_codes_to_short_repo_names = HashWithIndifferentAccess.new(I18n.t('ldpd.short.repo'))

    new_hash = {}

    full_repo_names_to_marc_codes.each {|key, value|
      new_hash[key] = marc_codes_to_short_repo_names[value]
    }

    return new_hash
  end
end
