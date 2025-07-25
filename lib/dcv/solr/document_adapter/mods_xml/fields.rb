require_relative 'solrizer_patch'
class Dcv::Solr::DocumentAdapter::ModsXml
  module Fields
    extend ActiveSupport::Concern
    include Solrizer::DefaultDescriptors::Normal

    KEY_DATE_EMPTY_BOUNDS = [nil, nil].freeze
    KEY_DATE_YEAR_BOUND_REGEX = /^(-?[0-9u]{1,4}).*/
    KEY_DATE_YEAR_UNBOUNDED = "uuuu"
    ORIGIN_INFO_DATES = ["dateCreated", "dateIssued", "dateOther"]
    # this part name pattern is taken from Hyacinth serialization rules
    # and must be changed if shelfLocator serialization changes in Hyacinth
    SHELF_LOCATOR_PART_NAME = /\b([A-Za-z]+)\s+[Nn][Oo]\.?\s*([^,]+)/

    module ClassMethods
      def normalize(t, strip_punctuation=false)
        # strip whitespace
        n_t = t.dup.strip
        # collapse intermediate whitespace
        n_t.gsub!(/\s+/, ' ')
        # pull off paired punctuation, and any leading punctuation
        if strip_punctuation
          # strip brackets
          n_t = n_t.sub(/^\((.*)\)$/, "\\1")
          n_t = n_t.sub(/^\{(.*)\}$/, "\\1")
          n_t = n_t.sub(/^\[(.*)\]$/, "\\1")
          n_t = n_t.sub(/^<(.*)>$/, "\\1")
          # strip quotes
          n_t = n_t.sub(/^"(.*)"$/, "\\1")
          n_t = n_t.sub(/^'(.*)'$/, "\\1")
          is_negative_number = n_t =~ /^-\d+(\.\d+)$/
          is_negative_coordinate = n_t =~ /^-\d+(\.\d+)?(\s*,\s*(-?\d+(\.\d+)?))?$/
          if strip_punctuation == :all
            n_t = n_t.gsub(/[[:punct:]]/, '')
          else
            n_t = n_t.sub(/^[[:punct:]]+/, '')
          end
          # this may have 'created' leading/trailing space, so strip
          n_t.strip!
          n_t = '-' + n_t if is_negative_number || is_negative_coordinate
        end
        n_t
      end

      def role_text_to_solr_field_name(role_text)
        role_text = normalize(role_text, false)
        ('role_' + role_text.gsub(/[^A-z]/, '_').downcase + '_ssim').gsub(/_+/, '_')
      end
    end

    extend ClassMethods

    def project_titles
      mods.xpath("./mods:relatedItem[@type='host' and @displayLabel='Project']", MODS_NS).collect do |p_node|
        Fields.normalize(main_title(p_node), true)
      end
    end

    def project_keys
      project_string_keys = []
      mods.xpath("./mods:relatedItem[@type='host' and @displayLabel='Project']/mods:identifier[@type='hyacinth-stringkey']", MODS_NS).collect do |n|
        project_string_keys << n.text.strip
      end
      mods.xpath("./mods:relatedItem[@type='host' and @displayLabel='Project']/mods:identifier[@type='uri']", MODS_NS).collect do |n|
        id_uri = URI(n.text)
        project_string_keys << id_uri.opaque.split('/')[-1].strip if id_uri.scheme == 'info'
      end
      project_string_keys.select { |k| k.present? }
    end

    def collection_titles
      mods.xpath("./mods:relatedItem[@type='host' and @displayLabel='Collection']", MODS_NS).collect do |p_node|
        Fields.normalize(main_title(p_node), true)
      end
    end

    def collection_keys
      collection_string_keys = mods.xpath("./mods:relatedItem[@displayLabel='Collection']", MODS_NS).map do |collection|
        collection.xpath("./mods:identifier[@type='CLIO']", MODS_NS).text
      end
      collection_string_keys.select { |k| k.present? }
    end

    def languages_iso639_2_text
      mods.xpath("./mods:language/mods:languageTerm[@type='text' and @authority='iso639-2']", MODS_NS).collect do |n|
        Fields.normalize(n.text, true)
      end
    end

    def languages_iso639_2_code
      mods.xpath("./mods:language/mods:languageTerm[@type='code' and @authority='iso639-2']", MODS_NS).collect do |n|
        Fields.normalize(n.text, true)
      end
    end

    def sort_title(node=mods)
      # include only the untyped [!@type] titleInfo, exclude noSort
      base_text = ''
      t = node.xpath('./mods:titleInfo[not(@type)]', MODS_NS).first
      if t
        t.children.each do |child|
          base_text << child.text unless child.name == 'nonSort'
        end
      end
      base_text = Fields.normalize(base_text, :all)
      # decompose and strip unicode combining characters
      base_text = base_text.unicode_normalize(:nfd)
      base_text.gsub!(/[\u0300-\u036F]/,'')
      # uppercase per Unicode, for ASCII/Latin
      # TODO: decide whether to use full Unicode case, other language options (Turkish, Lithuanian, etc.)
      base_text = base_text.upcase(:ascii)
      base_text = nil if base_text.empty?
      base_text
    end

    def main_title(node=mods)
      # include only the untyped [!@type] titleInfo
      t = node.xpath('./mods:titleInfo[not(@type)]', MODS_NS).first
      if t
        Fields.normalize(t.text).gsub(/[\n\r]+/,'').gsub(/\s{2,}/,' ')
      else
        nil
      end
    end

    def titles(node=mods)
      # all titles without descending into relatedItems
      # For now, this only includes the main title and selected alternate_titles
      all_titles = []
      all_titles << main_title unless main_title.nil?
      all_titles += alternative_titles unless alternative_titles.nil?
    end

    def alternative_titles(node=mods)
      node.xpath('./mods:titleInfo[@type and (@type="alternative" or @type="abbreviated" or @type="translated" or @type="uniform")]', MODS_NS).collect do |t|
        Fields.normalize(t.text).gsub(/[\n\r]+/,'').gsub(/\s{2,}/,' ')
      end
    end

    def clio_ids(node=mods)
      node.xpath('./mods:identifier[@type="CLIO"]', MODS_NS).collect do |t|
        Fields.normalize(t.text)
      end
    end

    def names(role_authority=nil, role=nil)
      # get all the name nodes
      # keep all child text except the role terms
      xpath = "./mods:name"
      unless role_authority.nil?
        xpath << "/mods:role/mods:roleTerm[@authority='#{role_authority.to_s}'"
        unless role.nil?
          xpath << " and normalize-space(text()) = '#{role.to_s.strip}'"
        end
        xpath << "]/ancestor::mods:name"
      end
      names = mods.xpath(xpath, MODS_NS).collect do |node|
        base_text = node.xpath('./mods:namePart', MODS_NS).collect { |c| c.text }.join(' ')
        Fields.normalize(base_text, true)
      end

      # Note: Removing subject names from name field extraction.
      # See: https://issues.cul.columbia.edu/browse/DCV-231 and https://issues.cul.columbia.edu/browse/SCV-102
      #xpath = "./mods:subject" + xpath[1,xpath.length]
      #mods.xpath(xpath, MODS_NS).each do |node|
      #  base_text = node.xpath('./mods:namePart', MODS_NS).collect { |c| c.text }.join(' ')
      #  names << Fields.normalize(base_text, true)
      #end

      names
    end

    def dates(node=mods)
      # get all the dateIssued with keyDate = 'yes', but not point = 'end'
    end

    def formats(node=mods)
      # get all the form values with authority != 'marcform'
      node.xpath("./mods:physicalDescription/mods:form[@authority != 'marcform']", MODS_NS).collect do |n|
        Fields.normalize(n.text)
      end
    end

    def repository_code(node=mods)
      # get the location/physicalLocation[@authority = 'marcorg']
      repo_code_node = node.xpath("./mods:location/mods:physicalLocation[@authority = 'marcorg']", MODS_NS).first

      if repo_code_node
        Fields.normalize(repo_code_node.text)
      else
        return nil
      end
    end

    def repository_text(node=mods)
      # get the location/physicalLocation[not(@authority)]
      repo_text_node = node.xpath("./mods:location/mods:physicalLocation[not(@authority)]", MODS_NS).first

      if repo_text_node
        Fields.normalize(repo_text_node.text)
      else
        return nil
      end
    end

    def translate_repo_marc_code(code, type)
      #code = Fields.normalize(code)

      if type == 'short'
        return translate_with_default(SHORT_REPO, code, 'Non-Columbia Location')
      elsif type == 'long'
        return translate_with_default(LONG_REPO, code, 'Non-Columbia Location')
      elsif type == 'full'
        return translate_with_default(FULL_REPO, code, 'Non-Columbia Location')
      end

      return nil
    end

    def translate_project_title(project_title, type)
      normalized_project_title = Fields.normalize(project_title)

      if type == 'short'
        return translate_with_default(SHORT_PROJ, normalized_project_title, normalized_project_title)
      elsif type == 'full'
        return translate_with_default(FULL_PROJ, normalized_project_title, normalized_project_title)
      end

      return nil
    end

    def shelf_locators(node=mods)
      values = node.xpath("./mods:location/mods:shelfLocator", MODS_NS).collect do |n|
        Fields.normalize(n.text, true)
      end
      values += node.xpath("./mods:location/mods:holdingSimple/mods:copyInformation/mods:shelfLocator", MODS_NS).collect do |n|
        Fields.normalize(n.text, true)
      end
      values
    end

    def sublocation(node=mods)
      values = node.xpath("./mods:location/mods:sublocation", MODS_NS).collect do |n|
        Fields.normalize(n.text, true)
      end
      values += node.xpath("./mods:location/mods:holdingSimple/mods:copyInformation/mods:sublocation", MODS_NS).collect do |n|
        Fields.normalize(n.text, true)
      end
      values
    end

    def enumerations(node=mods)
      node.xpath("./mods:location/mods:holdingSimple/mods:copyInformation/mods:enumerationAndChronology", MODS_NS).map do |n|
        Fields.normalize(n.text, true)
      end
    end

    def textual_dates(node=mods)
      dates = []
      ORIGIN_INFO_DATES.each do |element|
        node.xpath("./mods:originInfo/mods:#{element}[not(@keyDate) and not(@point) and not(@encoding)]", MODS_NS).collect do |n|
          dates << n.text.strip
        end
      end
      return dates
    end

    def key_date_range(node=mods)
      dates = []
      encodings = ['w3cdtf','iso8601']
      ORIGIN_INFO_DATES.each do |element|
        encodings.each do |encoding|
          xpath = "./mods:originInfo/mods:#{element}[(@keyDate) and (@encoding = '#{encoding}')]"
          node.xpath(xpath, MODS_NS).collect do |n|
            range = [Fields.normalize(n.text, true)]
            if n['point'] != 'end'
              n.xpath("../mods:#{element}[(@encoding = '#{encoding}' and @point = 'end')]", MODS_NS).each do |ep|
                range << Fields.normalize(ep.text, true)
              end
            end
            dates << range
          end
        end
      end
      return dates.first || dates
    end

    def date_range_to_textual_date(start_year, end_year)
      return nil if start_year.blank? && end_year.blank?
      start_year = start_year&.to_i # to remove zero-padding if present
      end_year = end_year&.to_i # to remove zero-padding if present

      if start_year == end_year
        return start_year < 0 ? ["#{start_year.to_s[1..-1]} BCE"] : [start_year.to_s]
      end

      start_date = (start_year > 0 ? start_year.to_s : start_year.to_s[1..-1]) if start_year
      end_date = (end_year > 0 ? end_year.to_s : end_year.to_s[1..-1]) if end_year
      return ["After #{start_date}#{' BCE' if start_year < 0}"] if end_date.blank?
      return ["Before #{end_date}#{' BCE' if end_year < 0}"] if start_date.blank?
      if start_year < 0
        return ["Between #{start_date} and #{end_date} BCE"] if end_year < 0
        return ["Between #{start_date} BCE and #{end_date} CE"]
      end
      ["Between #{start_date} and #{end_date}"]
    end

    def notes_by_type(node=mods)
      results = {}
      normal_date_types = ['date','date_source']
      node.xpath("./mods:note", MODS_NS).collect do |n|
        type = n.attr('type')
        type = 'untyped' if type.blank?
        normal_type = type.downcase
        normal_type.gsub!(/\s/,'_')
        normal_type = 'date' if normal_date_types.include?(normal_type)
        field_name = "lib_#{normal_type}_notes_ssm"
        results[field_name] ||= []
        results[field_name] << Fields.normalize(n.text, true)
      end
      results
    end

    def add_notes_by_type!(solr_doc, node=mods)
      notes_by_type(mods).each do |solr_field_name, values|
        solr_doc[solr_field_name] ||= []
        solr_doc[solr_field_name].concat(values - solr_doc[solr_field_name])
      end
    end

    def item_in_context_url(node=mods)
      item_in_context_url_val = []
      node.xpath("./mods:location/mods:url[@access='object in context']", MODS_NS).collect do |n|
        item_in_context_url_val << Fields.normalize(n.text, true)
      end
      item_in_context_url_val
    end

    def non_item_in_context_url(node=mods)
      non_item_in_context_url_val = []
      node.xpath("./mods:location/mods:url[not(@access='object in context')]", MODS_NS).collect do |n|
        non_item_in_context_url_val << Fields.normalize(n.text, true)
      end
      non_item_in_context_url_val
    end

    def project_url(node=mods)
      project_url_val = []
      node.xpath("./mods:relatedItem[@type='host' and @displayLabel='Project']/mods:location/mods:url", MODS_NS).collect do |n|
        project_url_val << Fields.normalize(n.text, true)
      end
      project_url_val
    end

    # Create a list of attribute hashes for top-level URL locations
    # @param node [Nokogiri::XML::Node] search context
    # @return [Array<Hash>] array of url locations as attribute hashes
    def url_locations(node=mods)
      node.xpath("./mods:location/mods:url", MODS_NS).map do |n|
        {access: n['access'], usage: n['usage'], displayLabel: n['displayLabel'], url: n.text.strip }.compact
      end
    end

    def all_subjects(node=mods)
      list_of_subjects = []

      node.xpath("./mods:subject[not(@authority) or @authority != 'Durst']/mods:topic", MODS_NS).collect do |n|
        list_of_subjects << Fields.normalize(n.text, true)
      end
      node.xpath("./mods:subject/mods:geographic", MODS_NS).collect do |n|
        list_of_subjects << Fields.normalize(n.text, true)
      end
      node.xpath("./mods:subject/mods:name/mods:namePart", MODS_NS).collect do |n|
        list_of_subjects << Fields.normalize(n.text, true)
      end
      node.xpath("./mods:subject/mods:temporal", MODS_NS).collect do |n|
        list_of_subjects << Fields.normalize(n.text, true)
      end
      node.xpath("./mods:subject/mods:titleInfo", MODS_NS).collect do |n|
        list_of_subjects << Fields.normalize(n.text, true)
      end
      node.xpath("./mods:subject/mods:genre", MODS_NS).collect do |n|
        list_of_subjects << Fields.normalize(n.text, true)
      end

      return list_of_subjects.uniq
    end

    def all_value_uris(node=mods)
      node.xpath(".//*[@valueURI]").map { |n| n['valueURI'] }
    end

    def durst_subjects(node=mods)
      list_of_subjects = []
      node.xpath("./mods:subject[@authority='Durst']/mods:topic", MODS_NS).collect do |n|
        list_of_subjects << Fields.normalize(n.text, true)
      end
      return list_of_subjects.uniq
    end

    def origin_info_place(node=mods)
      places = []
      node.xpath("./mods:originInfo/mods:place/mods:placeTerm", MODS_NS).collect do |n|
        places << Fields.normalize(n.text, true)
      end
      return places
    end

    def classification_other(node=mods)
      classification_other_values = []
      node.xpath("./mods:classification[@authority='z']", MODS_NS).collect do |n|
        classification_other_values << Fields.normalize(n.text, true)
      end
      return classification_other_values
    end

    def origin_info_place_for_display(node=mods)
      # If there are multiple origin_info place elements, choose only the ones without valueURI attributes.  Otherwise show the others.
      places_without_uri = node.xpath("./mods:originInfo/mods:place/mods:placeTerm[not(@valueURI)]", MODS_NS).collect do |n|
        Fields.normalize(n.text, true)
      end
      return places_without_uri if places_without_uri.present?
      node.xpath("./mods:originInfo/mods:place/mods:placeTerm[@valueURI]", MODS_NS).collect do |n|
        Fields.normalize(n.text, true)
      end
    end

    def coordinates(node=mods)
      coordinate_values = []
      node.xpath("./mods:subject/mods:cartographics/mods:coordinates", MODS_NS).collect do |n|
        nt = Fields.normalize(n.text, true)
        if nt.match(/-?\d+\.\d+\s*,\s*-?\d+\.\d+\s*/) # Expected coordinate format: 40.123456,-73.5678
          nt = nt.sub(/\s*,\s*/, ',')
          coordinate_values << nt
        end
      end
      coordinate_values
    end

    def archive_org_identifiers(node=mods)
      node.xpath('./mods:identifier[@type="archive.org"]', MODS_NS).collect do |t|
        {
          displayLabel: t['displayLabel'] || Fields.normalize(t.text),
          id: Fields.normalize(t.text)
        }.compact
      end
    end

    def archive_org_identifier(node=mods)
      node.at_xpath('./mods:identifier[@type="archive.org"]', MODS_NS)&.tap do |t|
        return Fields.normalize(t.text)
      end
    end

    def archives_space_identifiers(node=mods)
      aspace_ids = node.xpath('./mods:identifier[@type="archivesSpace"]', MODS_NS)&.collect do |t|
        Fields.normalize(t.text)
      end
      aspace_ids&.compact
    end

    def add_names_by_text_role!(solr_doc)
      # Note: These roles usually come from http://www.loc.gov/marc/relators/relaterm.html,
      # but there are known cases when non-marc relator values are used (e.g. 'Owner/Agent'),
      # and those roles won't have marcrelator codes.
      # e.g. author_ssim = ['Author 1', 'Author 2'] or project_director_ssim = ['Director 1', 'Director 2']
      roleterm_xpath_segment = "mods:roleTerm[@type='text' and string-length(text()) > 0]"
      names_with_roles_xpath = "./mods:name/mods:role/#{roleterm_xpath_segment}/ancestor::mods:name"
      mods.xpath(names_with_roles_xpath, MODS_NS).collect do |node|
        name_text = node.xpath('./mods:namePart', MODS_NS).collect { |c| c.text }.join(' ')
        name_text = Fields.normalize(name_text, true)
        solr_role_fields = Set.new
        node.xpath("./mods:role/#{roleterm_xpath_segment}", MODS_NS).collect do |role_node|
          solr_role_fields << Fields.role_text_to_solr_field_name(role_node.text)
        end

        solr_role_fields.each do |solr_field_name|
          solr_doc[solr_field_name] ||= []
          solr_doc[solr_field_name] << name_text
        end
      end
    end

    def add_shelf_locator_facets!(solr_doc, shelf_locator_values = shelf_locators)
      accumulated_values = {}
      shelf_locator_values.each do |val|
        if val.match(SHELF_LOCATOR_PART_NAME)
          val.scan(SHELF_LOCATOR_PART_NAME) do |part_match|
            part_type = part_match[0].dup.downcase.singularize
            # some collections use a semicolon concatenated list rather than separate shelfLocators
            # we will explode these into separate facetable values
            value_list = part_match[1].split(/;\s*/)
            parsed_values = value_list.map do |subvalue|
              # if a value has been 'redundantly' labeled with the part type, strip that part off the facet
              if subvalue.downcase.index(part_type) == 0
                pattern = Regexp.new("#{part_type}(e?s)?[[:space:][:punct:]]*", true)
                subvalue.sub!(pattern,'')
              end
              Fields.normalize(subvalue, true)
            end
            (accumulated_values[part_type] ||= []).concat parsed_values
          end
        end
      end
      solr_doc['lib_shelf_box_sim'] = accumulated_values['box']&.uniq
      solr_doc['lib_shelf_folder_sim'] = accumulated_values['folder']&.uniq
      solr_doc
    end

    def archival_context_json(node=mods)
      node.xpath("./mods:relatedItem[@displayLabel='Collection']", MODS_NS).map do |collection|
        collection_title = collection.xpath("./mods:titleInfo/mods:title", MODS_NS).text
        collection_id = collection.xpath("./mods:titleInfo/@valueURI", MODS_NS).text
        collection_bib_id = collection.xpath("./mods:identifier[@type='CLIO']", MODS_NS).text
        collection_org = collection.xpath("./mods:part/mods:detail/mods:title", MODS_NS).map do |title|
          {
            'ead:level' => title[:level],
            'dc:type' => title[:type],
            'dc:title' => title.text
          }
        end
        unless collection_org.empty?
          collection_org.sort! { |a,b| a['ead:level'] <=> b['ead:level'] }
          collection_org.each_with_index {|node, ix| node['@id'] = "_:n#{ix}"}
          collection_org[0].delete('ead:level')
          while collection_org.length > 1 do
            collection_org[-1].delete('ead:level')
            tail = collection_org.pop
            tail.delete('ead:level')
            collection_org[-1]['dc:hasPart'] = tail
          end
        end
        {
          '@context': {'dc': "http://purl.org/dc/terms/"},
          '@id' => collection_id,
          'dc:title' => collection_title,
          'dc:bibliographicCitation' => {
            '@id' => "https://clio.columbia.edu/catalog/#{collection_bib_id}",
            '@type' => 'dc:BibliographicResource'
          },
          'dc:coverage' => collection_org
        }
      end
    end

    def copyright_statement(node=mods)
      node.at_xpath('./mods:accessCondition[@type="use and reproduction"]', MODS_NS)&.tap do |t|
        return t['xlink:href']
      end
    end

    def reading_room_locations(node=mods)
      node.xpath("./mods:extension/cul:readingRoom", MODS_NS).map { |room_node| room_node.attr('valueUri') }
    end

    def search_scope(node=mods)
      node.xpath("./mods:extension/cul:searchScope", MODS_NS).map { |scope_node| scope_node.attr('value') }
    end

    def iiif_properties(node=mods)
      behaviors = node.xpath("./mods:extension/iiif_pres3:behavior", MODS_NS).map do |behavior_node|
        behavior_node.text.strip.downcase
      end
      behaviors = nil if behaviors.blank?
      viewing_direction = node.xpath("./mods:extension/iiif_pres3:viewingDirection", MODS_NS).first
      viewing_direction = viewing_direction.text.strip.downcase if viewing_direction
      {'iiif_viewing_direction_ssi' => viewing_direction, 'iiif_behavior_ssim' => behaviors}.compact
    end

    def hyacinth_uuid(node=mods)
      uuids = node.xpath("./mods:recordInfo/mods:recordIdentifier[@source='hyacinth']", MODS_NS)
      uuids.present? ? uuids.first.text.strip.downcase : nil
    end

    def to_solr(solr_doc={})
      solr_doc = (defined? super) ? super : solr_doc
      return solr_doc if mods.nil?  # There is no mods.  Return because there is nothing to process, otherwise NoMethodError will be raised by subsequent lines.

      solr_doc["all_text_teim"] ||= []

      solr_doc["title_si"] = sort_title
      solr_doc["title_ssm"] = titles
      solr_doc["title_ssm"].uniq!
      solr_doc["alternative_title_ssm"] = alternative_titles
      solr_doc["all_text_teim"] += solr_doc["alternative_title_ssm"]
      solr_doc["clio_ssim"] = clio_ids

      uuid = hyacinth_uuid
      solr_doc["hyacinth_uuid_ssi"] = uuid if uuid

      solr_doc["archive_org_identifier_ssi"] = archive_org_identifier
      solr_doc["archive_org_identifiers_json_ss"] = JSON.generate(archive_org_identifiers)
      solr_doc["archives_space_identifier_ssim"] = archives_space_identifiers
      solr_doc["lib_collection_sim"] = collection_titles
      solr_doc["collection_key_ssim"] = collection_keys.uniq
      solr_doc["lib_name_sim"] = names
      solr_doc["lib_name_teim"] = solr_doc["lib_name_sim"]
      solr_doc["all_text_teim"] += solr_doc["lib_name_teim"]
      solr_doc["lib_all_subjects_ssm"] = all_subjects
      solr_doc["durst_subjects_ssim"] = durst_subjects
      solr_doc["lib_all_subjects_teim"] = solr_doc["lib_all_subjects_ssm"]
      solr_doc["all_text_teim"] += solr_doc["lib_all_subjects_teim"]
      solr_doc["lib_name_ssm"] = solr_doc["lib_name_sim"]
      solr_doc["lib_author_sim"] = names(:marcrelator, 'aut')
      solr_doc["lib_recipient_sim"] = names(:marcrelator, 'rcp')
      solr_doc["lib_format_sim"] = formats
      solr_doc["lib_genre_ssim"] = solr_doc["lib_format_sim"].dup if solr_doc["lib_genre_ssim"].blank?
      solr_doc["lib_shelf_sim"] = shelf_locators
      add_shelf_locator_facets!(solr_doc, shelf_locators)
      solr_doc['location_shelf_locator_ssm'] = solr_doc["lib_shelf_sim"]
      solr_doc["all_text_teim"] += solr_doc["lib_shelf_sim"]
      solr_doc["lib_enumeration_ssim"] = enumerations
      solr_doc['lib_sublocation_sim'] = sublocation
      solr_doc['lib_sublocation_ssm'] = solr_doc['lib_sublocation_sim']
      solr_doc["all_text_teim"] += solr_doc['lib_sublocation_sim']
      solr_doc["lib_date_textual_ssm"] = textual_dates
      solr_doc["lib_item_in_context_url_ssm"] = item_in_context_url
      solr_doc["lib_non_item_in_context_url_ssm"] = non_item_in_context_url
      solr_doc["location_url_json_ss"] = JSON.generate(url_locations)
      solr_doc["lib_project_url_ssm"] = project_url
      solr_doc["origin_info_place_ssm"] = origin_info_place
      solr_doc["origin_info_place_for_display_ssm"] = origin_info_place_for_display
      solr_doc["classification_other_ssim"] = classification_other
      solr_doc["value_uri_ssim"] = all_value_uris
      solr_doc["all_text_teim"] += solr_doc['value_uri_ssim']

      repo_marc_code = repository_code
      unless repo_marc_code.nil?
        solr_doc["lib_repo_code_ssim"] = [repo_marc_code]
        solr_doc["lib_repo_short_ssim"] = [translate_repo_marc_code(repo_marc_code, 'short')]
        solr_doc["lib_repo_long_sim"] = [translate_repo_marc_code(repo_marc_code, 'long')]
        solr_doc["lib_repo_full_ssim"] = [translate_repo_marc_code(repo_marc_code, 'full')]
      end
      solr_doc["lib_repo_text_ssm"] = repository_text

      project_title_values = project_titles
      unless project_title_values.nil?
        solr_doc["lib_project_short_ssim"] = []
        solr_doc["lib_project_full_ssim"] = []
        project_title_values.each {|project_title|
          solr_doc["lib_project_short_ssim"] << translate_project_title(project_title, 'short')
          solr_doc["lib_project_full_ssim"] << translate_project_title(project_title, 'full')
        }
        solr_doc["lib_project_short_ssim"].uniq!
        solr_doc["lib_project_full_ssim"].uniq!
      end
      solr_doc["project_key_ssim"] = project_keys.uniq

      # Create convenient start and end date values based on one of the many possible originInfo/dateX elements.
      start_date, end_date = key_date_range

      if start_date.present? || end_date.present?
        start_year, end_year = key_date_year_bounds(start_date, end_date)

        solr_doc["lib_start_date_year_itsi"] = start_year.to_i if start_year.present?
        solr_doc["lib_end_date_year_itsi"] = end_year.to_i if end_year.present?
        if start_year.present? || end_year.present?
          solr_doc["lib_date_year_range_si"] =
            (start_year.present? ? start_year : KEY_DATE_YEAR_UNBOUNDED) +
            '-' + (end_year.present? ? end_year : KEY_DATE_YEAR_UNBOUNDED)
          solr_doc["lib_date_year_range_ss"] =
            (start_year.present? ? start_year : '*') +
            '-' + (end_year.present? ? end_year : '*')
        end
        # When no textual date is available, fall back to other date data (if available)
        if solr_doc["lib_date_textual_ssm"].blank?
          solr_doc["lib_date_textual_ssm"] = date_range_to_textual_date(start_year, end_year)
        end
      end

      # Geo data
      solr_doc["geo"] = coordinates
      solr_doc["has_geo_bsi"] = true if solr_doc["geo"].present?

      ## Handle alternate form of language authority for language_language_term_text_ssim
      ## We already capture elements when authority="iso639-2b", but we want to additionally
      ## capture language elements when authority="iso639-2".
      solr_doc['language_language_term_text_ssim'] ||= []
      solr_doc['language_language_term_text_ssim'] += languages_iso639_2_text
      solr_doc['language_language_term_code_ssim'] ||= []
      solr_doc['language_language_term_code_ssim'] +=languages_iso639_2_code

      archival_context = archival_context_json
      solr_doc['archival_context_json_ss'] = JSON.generate(archival_context) if archival_context.present?


      # Add names to role-derived keys
      add_names_by_text_role!(solr_doc)

      # Add names to type-derived keys
      add_notes_by_type!(solr_doc)

      solr_doc['copyright_statement_ssi'] = copyright_statement

      # Publish Target/Site fields for location indexes
      solr_doc['search_scope_ssi'] = search_scope.first
      solr_doc['reading_room_ssim'] = reading_room_locations

      solr_doc.merge!(iiif_properties(mods))
      othertype_fields = othertype_relations(mods)
      solr_doc.merge!(othertype_fields)
      solr_doc["all_text_teim"] += othertype_fields.values.flatten
      solr_doc
    end

    def zero_pad_year(year)
      year = year.to_s
      is_negative = year.start_with?('-')
      year_without_sign = (is_negative ? year[1, year.length]: year)
      if year_without_sign.length < 4
        year_without_sign = year_without_sign.rjust(4, '0')
      end

      return (is_negative ? '-' : '') + year_without_sign
    end

    # for given textual start and end dates beginning with a year:
    # substitute 'u' appropriately, return an array consisting of:
    # two zero-padded 4 digit years with a negative sign for BCE dates
    # nil for entirely uncertain or unindicated dates
    # nil if the start/end point was incorrectly entered
    def key_date_year_bounds(start_date, end_date)
      start_year = nil
      end_year = nil

      start_date = nil if start_date == 'uuuu'
      end_date = nil if end_date == 'uuuu'

      end_date = start_date if end_date.blank?
      start_date = end_date if start_date.blank?

      unless start_date.blank?
        start_year_match = start_date.match(KEY_DATE_YEAR_BOUND_REGEX)

        if start_year_match && start_year_match.captures.length > 0
          start_year = start_year_match.captures[0]
          start_year.gsub!('u', start_year.start_with?('-') ? '9' : '0')
          start_year = zero_pad_year(start_year)
        end
      end

      unless end_date.blank?
        end_year_match = end_date.match(KEY_DATE_YEAR_BOUND_REGEX)
        if end_year_match && end_year_match.captures.length > 0
          end_year = end_year_match.captures[0]
          end_year.gsub!('u', end_year.start_with?('-') ? '0' : '9')
          end_year = zero_pad_year(end_year)
        end
      end
      return KEY_DATE_EMPTY_BOUNDS if (end_year && start_year) && end_year.to_i < start_year.to_i
      [start_year, end_year]
    end

    # Create a map of field names to value arrays for relatedItem[@otherType]
    # @param node [Nokogiri::XML::Node] search context
    # @return [Hash<String, Array<String>] map of field name strings to value string arrays
    def othertype_relations(node)
      field_values = {}
      mods.xpath("./mods:relatedItem[@otherType]/mods:titleInfo", MODS_NS).each do |title|
        field_name = title.parent['otherType'].underscore.downcase.split(/[^a-z]+/).compact.join('_')
        field_name = "rel_other_#{field_name}_ssim"
        (field_values[field_name] ||= []) << title.text.strip
      end
      mods.xpath("./mods:relatedItem[@otherType]/mods:identifier", MODS_NS).each do |xml_value|
        field_name = xml_value.parent['otherType'].underscore.downcase.split(/[^a-z]+/).compact.join('_')
        field_name = "rel_other_#{field_name}_identifier_ssim"
        (field_values[field_name] ||= []) << xml_value.text.strip
      end
      field_values
    end
  end
end
