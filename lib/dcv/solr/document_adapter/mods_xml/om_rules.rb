class Dcv::Solr::DocumentAdapter::ModsXml
  module OmRules
    SHORT_REPO = "ldpd.short.repo"
    LONG_REPO  = "ldpd.long.repo"
    FULL_REPO = "ldpd.full.repo"
    SHORT_PROJ = "ldpd.short.project"
    FULL_PROJ = "ldpd.full.project"

    def to_solr(solr_doc={})
      solr_doc = (defined? super) ? super : solr_doc
      return solr_doc if mods.nil?  # There is no mods.  Return because there is nothing to process, otherwise NoMethodError will be raised by subsequent lines.

      solr_doc["all_text_teim"] ||= []
      #t.main_title_info(:path=>'titleInfo', :index_as=>[], :attributes=>{:type=>:none}){
      # t.non_sort(:path=>"nonSort", :index_as=>[])
      # t.main_title(:path=>"title", :index_as=>[])
      #}
      
      #t.title(proxy: [:mods, :main_title_info, :main_title], type: :string, index_as: [:searchable, :sortable])
      mods.xpath("./mods:titleInfo[not(@type)]/mods:title", MODS_NS).each_with_index do |main_title, ix|
        (solr_doc['title_teim'] ||= []).concat(textable(main_title.text))
        if ix == 0
          solr_doc['title_si'] = main_title.text
        end
      end
      solr_doc['title_teim']&.uniq!
      #t.title_display(proxy:[:mods, :main_title_info], type: :string, index_as: [:displayable])
      title_display_text = mods.xpath("./mods:titleInfo[not(@type)]", MODS_NS).map(&:text)
      solr_doc['title_display_ssm'] = title_display_text if title_display_text.present?

      #t.search_title_info(:path=>'titleInfo', :index_as=>[]){
      #  t.search_title(:path=>'title', :index_as=>[:textable])
      #}
      title_text = mods.xpath("./mods:titleInfo/mods:title", MODS_NS).map(&:text)
      solr_doc['all_text_teim'].concat(textable(title_text)) if title_text.present?

      #t.part(:path=>"relatedItem", :attributes=>{:type=>"constituent"}, :index_as=>[]){
      #  t.part_title_info(:path=>'titleInfo', :index_as=>[]){
      #    t.lib_part(:path=>'title',:index_as=>[])
      #  }
      #}
      #t.lib_part(:proxy=>[:part,:part_title_info], :index_as=>[:displayable, :textable])
      part_text = mods.xpath("./mods:relatedItem[@type = 'constituent']/mods:titleInfo", MODS_NS).map(&:text)
      if part_text.present?
        solr_doc['lib_part_ssm'] = part_text
        solr_doc['all_text_teim'].concat(textable(part_text))
      end

      #t.project(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Project"}, :index_as=>[]){
      #  t.project_title_info(:path=>'titleInfo', :index_as=>[]){
      #    t.lib_project(:path=>'title',:index_as=>[])
      #  }
      #}
      #t.lib_project(:proxy=>[:project,:project_title_info], :index_as=>[:project_textable])
      project_text = mods.xpath("./mods:relatedItem[@type = 'host' and @displayLabel = 'Project']/mods:titleInfo", MODS_NS).map(&:text)
      if project_text.present?
        solr_doc['all_text_teim'].concat(project_textable(project_text))
      end

      #t.collection(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Collection"}, :index_as=>[]){
      #  t.collection_title_info(:path=>'titleInfo', :index_as=>[]){
      #    t.lib_collection(:path=>'title', :index_as=>[])
      #  }
      #}
      #t.lib_collection(:proxy=>[:collection,:collection_title_info], :index_as=>[:displayable])
      collection_text = mods.xpath("./mods:relatedItem[@type = 'host' and @displayLabel = 'Collection']/mods:titleInfo", MODS_NS).map(&:text)
      if collection_text.present?
        solr_doc['lib_collection_ssm'] = collection_text.map { |v| normal(v) }
        solr_doc['all_text_teim'].concat(textable(collection_text))
      end


      # identifier pattern matches
      #t.identifier(:path=>"identifier", :attributes=>{:type=>"local"}, :type=>:string, :index_as=>[:symbol, :textable])
      local_identifier_text = mods.xpath("./mods:identifier[@type = 'local']", MODS_NS).map(&:text)
      solr_doc['identifier_ssim'] = local_identifier_text
      solr_doc['all_text_teim'].concat textable(local_identifier_text)


      #t.accession_number(:path=>"identifier", :attributes=>{:type=>"accession_number"}, :type=>:string, :index_as=>[:textable])
      accession_number_text = mods.xpath("./mods:identifier[@type = 'accession_number']", MODS_NS).map(&:text)
      solr_doc['all_text_teim'].concat textable(accession_number_text)

      #t.clio(:path=>"identifier", :attributes=>{:type=>"CLIO"}, :data_type=>:symbol, :index_as=>[:symbol, :textable])
      clio_text = mods.xpath("./mods:identifier[@type = 'CLIO']", MODS_NS).map(&:text)
      solr_doc['clio_ssim'] = clio_text
      solr_doc['all_text_teim'].concat textable(clio_text)

      #t.abstract(:index_as=>[:displayable, :textable])
      abstract_text = mods.xpath("./mods:abstract", MODS_NS).map(&:text)
      solr_doc['abstract_ssm'] = abstract_text
      solr_doc['all_text_teim'].concat textable(abstract_text)

      #t.table_of_contents(:path=>"tableOfContents", :index_as=>[:displayable, :textable])
      table_of_contents_text = mods.xpath("./mods:tableOfContents", MODS_NS).map(&:text)
      solr_doc['table_of_contents_ssm'] = table_of_contents_text
      solr_doc['all_text_teim'].concat textable(table_of_contents_text)

      #t.subject(:index_as=>[:textable]){
      mods.xpath("./mods:subject", MODS_NS).each do |subject|
        solr_doc['all_text_teim'].concat(textable(subject.text))
      #  t.topic(:index_as=>[:facetable, :displayable])
        topic_text = subject.xpath("mods:topic", MODS_NS).map(&:text)
        if topic_text.present?
          solr_doc['subject_topic_sim'] = topic_text
          solr_doc['subject_topic_ssm'] = topic_text
        end
      #  t.geographic(:index_as=>[:facetable])
        geographic_text = subject.xpath("mods:geographic", MODS_NS).map(&:text)
        solr_doc['subject_geographic_sim'] = geographic_text if geographic_text.present?
      #  t.hierarchical_geographic(:path=>'hierarchicalGeographic', :index_as=>[]){
        subject.xpath("mods:hierarchicalGeographic", MODS_NS).each do |hierarchical_geographic|
      #    t.country(:index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:country", MODS_NS).each do |country|
            (solr_doc['subject_hierarchical_geographic_country_ssim'] ||= []) << country.text
            solr_doc['all_text_teim'] << country.text
          end
      #    t.province(:index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:province", MODS_NS).each do |province|
            (solr_doc['subject_hierarchical_geographic_province_ssim'] ||= []) << province.text
            solr_doc['all_text_teim'] << province.text
          end
      #    t.region(:index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:region", MODS_NS).each do |region|
            (solr_doc['subject_hierarchical_geographic_region_ssim'] ||= []) << region.text
            solr_doc['all_text_teim'] << region.text
          end
      #    t.state(:index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:state", MODS_NS).each do |state|
            (solr_doc['subject_hierarchical_geographic_state_ssim'] ||= []) << state.text
            solr_doc['all_text_teim'] << state.text
          end
      #    t.county(:index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:county", MODS_NS).each do |county|
            (solr_doc['subject_hierarchical_geographic_county_ssim'] ||= []) << county.text
            solr_doc['all_text_teim'] << county.text
          end
      #    t.borough(:path=>'citySection', :attributes=>{:'citySectionType'=>"borough"}, :index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:citySection[@citySectionType = 'borough']", MODS_NS).each do |borough|
            (solr_doc['subject_hierarchical_geographic_borough_ssim'] ||= []) << borough.text
            solr_doc['all_text_teim'] << borough.text
          end
      #    t.city(:index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:city", MODS_NS).each do |city|
            (solr_doc['subject_hierarchical_geographic_city_ssim'] ||= []) << city.text
            solr_doc['all_text_teim'] << city.text
          end
      #    t.neighborhood(:path=>'citySection', :attributes=>{:'citySectionType'=>"neighborhood"}, :index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:citySection[@citySectionType = 'neighborhood']", MODS_NS).each do |neighborhood|
            (solr_doc['subject_hierarchical_geographic_neighborhood_ssim'] ||= []) << neighborhood.text
            solr_doc['all_text_teim'] << neighborhood.text
          end
      #    t.zip_code(:path=>'citySection', :attributes=>{:'citySectionType'=>"zip code"}, :index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:citySection[@citySectionType = 'zip code']", MODS_NS).each do |zip_code|
            (solr_doc['subject_hierarchical_geographic_zip_code_ssim'] ||= []) << zip_code.text
            solr_doc['all_text_teim'] << zip_code.text
          end
      #    t.area(:index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:area", MODS_NS).each do |area|
            (solr_doc['subject_hierarchical_geographic_area_ssim'] ||= []) << area.text
            solr_doc['all_text_teim'] << area.text
          end
      #    t.street(:path=>'citySection', :attributes=>{:'citySectionType'=>"street"}, :index_as=>[:symbol, :textable])
          hierarchical_geographic.xpath("mods:citySection[@citySectionType = 'street']", MODS_NS).each do |street|
            (solr_doc['subject_hierarchical_geographic_street_ssim'] ||= []) << street.text
            solr_doc['all_text_teim'] << street.text
          end
        end
      #  }
      end
      #}
      #t.type_of_resource(:path=>"typeOfResource", :index_as=>[:displayable])
      type_of_resource_text = mods.xpath("./mods:typeOfResource", MODS_NS).map(&:text)
      solr_doc['type_of_resource_ssm'] = type_of_resource_text if type_of_resource_text.present?

      #t.physical_description(:path=>"physicalDescription", :index_as=>[]){
      mods.xpath("./mods:physicalDescription", MODS_NS).each do |physical_description|
      #  t.form_marc(:path=>"form", :attributes=>{:authority=>"marcform"}, :index_as=>[:displayable])
        form_marc = physical_description.xpath("mods:form[@authority='marcform']", MODS_NS).map(&:text)
        solr_doc['physical_description_form_marc_ssm'] = form_marc if form_marc.present?

      #  t.form_aat(:path=>"form", :attributes=>{:authority=>"aat"}, :index_as=>[:displayable, :facetable])
        form_aat = physical_description.xpath("mods:form[@authority='aat']", MODS_NS).map(&:text)
        if form_aat.present?
          solr_doc['physical_description_form_aat_ssm'] = form_aat
          solr_doc['physical_description_form_aat_sim'] = form_aat
        end

      #  t.form_local(:path=>"form", :attributes=>{:authority=>"local"}, :index_as=>[:displayable, :facetable])
        form_local = physical_description.xpath("mods:form[@authority='local']", MODS_NS).map(&:text)
        if form_local.present?
          solr_doc['physical_description_form_local_ssm'] = form_local
          solr_doc['physical_description_form_local_sim'] = form_local
        end

      #  t.form(:attributes=>{:authority=>:none}, :index_as=>[:displayable])
        form_none = physical_description.xpath("mods:form[not(@authority)]", MODS_NS).map(&:text)
        if form_none.present?
          solr_doc['physical_description_form_ssm'] = form_none
        end

      #  t.form_nomarc(:path=>"form[@authority !='marcform']", :index_as=>[])
      #  <-- t.lib_format(:proxy=>[:physical_description, :form_nomarc], :index_as=>[:displayable, :facetable, :textable])
        form_nomarc = physical_description.xpath("mods:form[@authority != 'marcform']", MODS_NS).map(&:text)
        if form_nomarc.present?
          solr_doc['lib_format_ssm'] = form_nomarc
          solr_doc['lib_format_sim'] = form_nomarc
          solr_doc['all_text_teim'].concat(textable(form_nomarc))
        end
      #  t.extent(:path=>"extent", :index_as=>[:searchable, :displayable])
        extent_text = physical_description.xpath("mods:extent", MODS_NS).map(&:text)
        if extent_text.present?
          solr_doc['physical_description_extent_teim'] = textable(extent_text)
          solr_doc['physical_description_extent_ssm'] = extent_text
        end

      #  t.reformatting_quality(:path=>"reformattingQuality", :index_as=>[:displayable])
        reformatting_quality = physical_description.xpath("mods:reformattingQuality", MODS_NS).map(&:text)
        solr_doc['physical_description_reformatting_quality_ssm'] = reformatting_quality if reformatting_quality.present?

      #  t.internet_media_type(:path=>"internetMediaType", :index_as=>[:displayable])
        internet_media_type = physical_description.xpath("mods:internetMediaType", MODS_NS).map(&:text)
        solr_doc['physical_description_internet_media_type_ssm'] = internet_media_type if internet_media_type.present?

      #  t.digital_origin(:path=>"digitalOrigin", :index_as=>[:displayable])
        digital_origin = physical_description.xpath("mods:digitalOrigin", MODS_NS).map(&:text)
        solr_doc['physical_description_digital_origin_ssm'] = digital_origin if digital_origin.present?
      end
      #}
      #t.location(:path=>"location", :index_as=>[]){
      mods.xpath("./mods:location", MODS_NS).each do |location|
      #  t.repo_text(:path=>"physicalLocation",:attributes=>{:authority=>:none},  :index_as=>[])
      #  t.lib_repo(path: "physicalLocation", attributes: {:authority=>"marcorg"}, index_as: [:textable])
      #  <-t.lib_repo(proxy: [:location, :lib_repo], type: :text, index_as: [:marc_code_textable])
        lib_repo_text = location.xpath("mods:physicalLocation[@authority = 'marcorg']", MODS_NS).map(&:text)
        if lib_repo_text.present?
          solr_doc['all_text_teim'].concat(textable(lib_repo_text))
          solr_doc['all_text_teim'].concat(marc_code_textable(lib_repo_text))
        end
      #  t.shelf_locator(:path=>"shelfLocator", :index_as=>[:displayable])
        locator_text = location.xpath("mods:shelfLocator", MODS_NS).map(&:text)
        if locator_text.present?
          solr_doc['location_shelf_locator_ssm'] = locator_text
        end
      #  t.sublocation(:path=>"sublocation", :index_as=>[:displayable])
        sublocation_text = location.xpath("mods:sublocation", MODS_NS).map(&:text)
        if sublocation_text.present?
          solr_doc['location_sublocation_ssm'] = sublocation_text
        end
      #  no index rule -- t.url
      end
      #}

      #no index rule -- t.top_level_location_url(:proxy=>[:mods, :location, :url])

      #t.name_usage_primary(
      #  :path=>'name',:attributes=>{:usage=>'primary'},
      #  :index_as=>[]){
      #  t.name_part(:path=>'namePart', :index_as=>[])
      #<--t.primary_name(proxy: [:name_usage_primary,:name_part], index_as: [:facetable, :displayable])
      name_primary_text = mods.xpath("./mods:name[@usage='primary']/mods:namePart", MODS_NS).map(&:text)
      if name_primary_text.present?
        solr_doc['primary_name_ssm'] = name_primary_text
        solr_doc['primary_name_sim'] = name_primary_text
      end
      #}

      #t.note(:path=>"note", :index_as=>[:textable])
      note_text = mods.xpath("./mods:note", MODS_NS).map(&:text)
      solr_doc['all_text_teim'].concat(textable(note_text)) if note_text.present?

      #t.access_condition(:path=>"accessCondition", :attributes=>{:type=>"useAndReproduction"}, :index_as => [:searchable, :symbol])
      condition_text = mods.xpath("./mods:accessCondition[@type='useAndReproduction']", MODS_NS).map(&:text)
      if condition_text.present?
        solr_doc['access_condition_teim'] = textable(condition_text)
        solr_doc['access_condition_ssim'] = condition_text
      end
      #t.record_info(:path=>"recordInfo", :index_as=>[]) {
      mods.xpath("./mods:recordInfo", MODS_NS).each do |record_info|
      # no indexing rules?
      #  t.record_creation_date(:path=>"recordCreationDate",:attributes=>{:encoding=>"w3cdtf"}, :index_as=>[])
      #  t.record_content_source(:path=>"recordContentSource",:attributes=>{:authority=>"marcorg"}, :index_as=>[])
      #  t.language_of_cataloging(:path=>"languageOfCataloging", :index_as=>[]){
      #    t.language_term(:path=>"languageTerm", :index_as=>[], :attributes=>{:type=>:none})
      #    <- t.language_term(:proxy=>[:record_info, :language_of_cataloging, :language_term])
      #    t.language_code(:path=>"languageTerm",:attributes=>{:type=>'code',:authority=>"iso639-2b"}, :index_as=>[])
      #    <- t.language_code(:proxy=>[:record_info, :language_of_cataloging, :language_code])
      #  }
      #  t.record_origin(:path=>"recordOrigin", :index_as=>[])
      end
      #}

      #t.language(:index_as=>[]){
      mods.xpath("mods:language", MODS_NS).each do |record_info|
      #  t.language_term_text(:path=>"languageTerm", :attributes=>{:authority=>'iso639-2b',:type=>'text'}, :index_as=>[:symbol, :textable])
        term_text = record_info.xpath("mods:languageTerm[@authority = 'iso639-2b' and @type = 'text']", MODS_NS).map(&:text)
        if term_text.present?
          solr_doc['language_language_term_text_ssim'] = term_text
          solr_doc['all_text_teim'].concat(textable(term_text))
        end
      #  t.language_term_code(:path=>"languageTerm", :attributes=>{:authority=>'iso639-2b',:type=>'code'}, :index_as=>[:symbol, :textable])
        code_text = record_info.xpath("mods:languageTerm[@authority = 'iso639-2b' and @type = 'code']", MODS_NS).map(&:text)
        if code_text.present?
          solr_doc['language_language_term_code_ssim'] = code_text
          solr_doc['all_text_teim'].concat(textable(code_text))
        end
      end
      #}

      #t.origin_info(:path=>"originInfo", :index_as=>[]){
      mods.xpath("./mods:originInfo", MODS_NS).each do |origin_info|
      #  t.date_issued(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes'}, :index_as=>[:displayable, :textable])
        date_issued_text = origin_info.xpath("mods:dateIssued[@encoding = 'w3cdtf' and @keyDate = 'yes']", MODS_NS).map(&:text)
        if date_issued_text.present?
          solr_doc['origin_info_date_issued_ssm'] = date_issued_text
          solr_doc['all_text_teim'].concat(textable(date_issued_text))
        end

      #  t.date_issued_start(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes',:point=>'start'}, :index_as=>[:displayable, :textable])
        date_issued_text = origin_info.xpath("mods:dateIssued[@encoding = 'w3cdtf' and @keyDate = 'yes' and @point = 'start']", MODS_NS).map(&:text)
        if date_issued_text.present?
          solr_doc['origin_info_date_issued_start_ssm'] = date_issued_text
          solr_doc['all_text_teim'].concat(textable(date_issued_text))
        end

      #  t.date_issued_end(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:point=>'end'}, :index_as=>[:displayable, :textable])
        date_issued_text = origin_info.xpath("mods:dateIssued[@encoding = 'w3cdtf' and @point = 'end']", MODS_NS).map(&:text)
        if date_issued_text.present?
          solr_doc['origin_info_date_issued_end_ssm'] = date_issued_text
          solr_doc['all_text_teim'].concat(textable(date_issued_text))
        end

      #  t.date_issued_textual(:path=>"dateIssued", :attributes=>{:encoding=>:none, :keyDate=>:none}, :index_as=>[:textable])
        date_issued_text = origin_info.xpath("mods:dateIssued[not(@encoding) and not(@keyDate)]", MODS_NS).map(&:text)
        solr_doc['all_text_teim'].concat(textable(date_issued_text)) if date_issued_text.present?

      #  t.date_created(:path=>"dateCreated", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes'}, :index_as=>[:displayable, :textable])
        date_created_text = origin_info.xpath("mods:dateCreated[@encoding = 'w3cdtf' and @keyDate = 'yes']", MODS_NS).map(&:text)
        if date_created_text.present?
          solr_doc['origin_info_date_created_ssm'] = date_created_text 
          solr_doc['all_text_teim'].concat textable(date_created_text)
        end

      #  t.date_created_start(:path=>"dateCreated", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes',:point=>'start'}, :index_as=>[:displayable, :textable])
        date_created_text = origin_info.xpath("mods:dateCreated[@encoding = 'w3cdtf' and @keyDate = 'yes' and @point = 'start']", MODS_NS).map(&:text)
        if date_created_text.present?
          solr_doc['origin_info_date_created_start_ssm'] = date_created_text 
          solr_doc['all_text_teim'].concat textable(date_created_text)
        end

      #  t.date_created_end(:path=>"dateCreated", :attributes=>{:encoding=>'w3cdtf',:point=>'end'}, :index_as=>[:displayable, :textable])
        date_created_text = origin_info.xpath("mods:dateCreated[@encoding = 'w3cdtf' and @point = 'end']", MODS_NS).map(&:text)
        if date_created_text.present?
          solr_doc['origin_info_date_created_end_ssm'] = date_created_text 
          solr_doc['all_text_teim'].concat textable(date_created_text)
        end

      #  t.date_created_textual(:path=>"dateCreated", :attributes=>{:encoding=>:none, :keyDate=>:none}, :index_as=>[:textable])
        date_created_text = origin_info.xpath("mods:dateCreated[not(@encoding) and not(@keyDate)]", MODS_NS).map(&:text)
        solr_doc['all_text_teim'].concat textable(date_created_text) if date_created_text.present?

      #  t.date_other(:path=>"dateOther", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes'}, :index_as=>[:displayable, :textable])
        date_other_text = origin_info.xpath("mods:dateOther[@encoding = 'w3cdtf' and @keyDate = 'yes']", MODS_NS).map(&:text)
        if date_other_text.present?
          solr_doc['origin_info_date_other_ssm'] = date_other_text 
          solr_doc['all_text_teim'].concat textable(date_other_text)
        end

      #  t.date_other_start(:path=>"dateOther", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes',:point=>'start'}, :index_as=>[:displayable, :textable])
        date_other_text = origin_info.xpath("mods:dateOther[@encoding = 'w3cdtf' and @keyDate = 'yes' and @point = 'start']", MODS_NS).map(&:text)
        if date_other_text.present?
          solr_doc['origin_info_date_other_start_ssm'] = date_other_text 
          solr_doc['all_text_teim'].concat textable(date_other_text)
        end

      #  t.date_other_end(:path=>"dateOther", :attributes=>{:encoding=>'w3cdtf',:point=>'end'}, :index_as=>[:displayable, :textable])
        date_other_text = origin_info.xpath("mods:dateOther[@encoding = 'w3cdtf' and @point = 'end']", MODS_NS).map(&:text)
        if date_other_text.present?
          solr_doc['origin_info_date_other_end_ssm'] = date_other_text 
          solr_doc['all_text_teim'].concat textable(date_other_text)
        end

      #  t.date_other_textual(:path=>"dateOther", :attributes=>{:encoding=>:none, :keyDate=>:none}, :index_as=>[:textable])
        date_other_text = origin_info.xpath("mods:dateOther[not(@encoding) and not(@keyDate)]", MODS_NS).map(&:text)
        solr_doc['all_text_teim'].concat(textable(date_other_text)) if date_other_text.present?

      #  t.publisher(:index_as=>[:displayable])
      # <- t.lib_publisher(:proxy=>[:mods, :origin_info, :publisher], :index_as=>[:displayable])
        publisher_text = origin_info.xpath('mods:publisher', MODS_NS).map(&:text)
        if publisher_text.present?
          solr_doc['origin_info_publisher_ssm'] = publisher_text
          solr_doc['lib_publisher_ssm'] = publisher_text
        end
      #  t.edition(:index_as=>[:displayable])
        edition_text = origin_info.xpath('mods:edition', MODS_NS).map(&:text)
        solr_doc['origin_info_edition_ssm'] = edition_text if edition_text.present?
      end
      #}

      #t.genre(:path=>"genre[@authority]",:index_as=>[])
      #t.lib_genre(:proxy=>[:mods,:genre],:index_as=>[:symbol, :textable])
      genre_text = mods.xpath("mods:genre[@authority]", MODS_NS).map(&:text)
      if genre_text.present?
        solr_doc['lib_genre_ssim'] = genre_text
        solr_doc['all_text_teim'].concat textable(genre_text)
      end

      solr_doc
    end

    def translate_with_default(prefix, value, default)
      begin
        # Using method below to handle translations because our YAML keys can contain periods and this doesn't play well with the translation dot-syntax
        translations = HashWithIndifferentAccess.new(I18n.t(prefix))
        if translations.has_key?(value)
          return translations[value]
        else
          return default
        end
      rescue
        return default
      end
    end

    def marc_code_textable(value)
      Array(value).map do |v|
        nv = normal(v)
        r = [translate_with_default(SHORT_REPO, nv, 'Non-Columbia Location')]
        r << translate_with_default(LONG_REPO, nv, 'Non-Columbia Location')
        r.uniq!
        r.join(' ')
      end
    end

    def project_textable(value)
      Array(value).map do |v|
        nv = normal(v)
        r = [translate_with_default(SHORT_PROJ, nv, nv)]
        r << translate_with_default(FULL_PROJ, nv, nv)
        r.uniq!
        r.join(' ')
      end
    end

    def project_facetable(value)
      Array(value).map do |v|
        nv = normal(v)
        translate_with_default(SHORT_PROJ, nv, nv)
      end
    end
  end
end