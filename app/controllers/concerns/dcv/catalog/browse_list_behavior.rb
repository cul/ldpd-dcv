# -*- encoding : utf-8 -*-
module Dcv::Catalog::BrowseListBehavior
  extend ActiveSupport::Concern

  # Browse list items must be accessible as facets from in solr (i.e. like facets)
  BROWSE_LISTS_KEY = 'browse_lists'
  BROWSE_LISTS = {
    'lib_name_sim' => {:display_label => 'Names', :short_description => 'People, corporate bodies and events that are represented in or by our items.'},
    'lib_format_sim' => {:display_label => 'Formats', :short_description => 'Original formats of our digitally-presented items.'},
    'lib_repo_long_sim' => {:display_label => 'Library Locations', :short_description => 'Archives where our items are stored.'}
  }

  # Browse List Logic

  def refresh_browse_lists_cache
    if Rails.env == 'development' || ! Rails.cache.exist?(BROWSE_LISTS_KEY)
      Rails.cache.write(BROWSE_LISTS_KEY, get_browse_lists);
    end
    @browse_lists = Rails.cache.read(BROWSE_LISTS_KEY)
  end

  def get_browse_lists

    hash_to_return = {}

    BROWSE_LISTS.each do |facet_field_name, options|
      hash_to_return[facet_field_name] = get_all_facet_values_and_counts(facet_field_name)
      hash_to_return[facet_field_name]['display_label'] = options[:display_label]
      hash_to_return[facet_field_name]['short_description'] = options[:short_description]
    end

    return hash_to_return
  end

  DIGITAL_PROJECTS = [
    {
			:name => "APIS: Advanced Papyrological Information System",
			:image => 'apis.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?ATK2059',
			:description => "APIS is a collaborative online catalog and library of digitized images of papyri and ostraca (potsherds with incriptions) dating from the period 400 BCE to 800 CE."
		},
		{
			:name => "Biggert Collection of Architectural Vignettes on Commercial Stationery",
			:image => 'biggert.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio7887951',
			:description => "Contains over 1,300 items of printed ephemera with architectural imagery from 1850-1920, spanning more than 350 cities and towns in forty-five states."
		},
		{
			:name => "Bunraku Collection Gallery",
			:image => 'bunraku.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?lweb0120',
			:description => "A sampler from the Barbara C. Adachi Collection of photographs of live bunraku theater performances from the second half of the 20th century."
		},
        {
            :name => "Children's Drawings of the Spanish Civil War",
            :image => 'spanish_civil_war_children_drawings.jpeg',
            :facet_value => 'Spanish Civil War',
            :external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio4278351',
            :description => "A virtual exhibition of drawings done by children evacuated to 'colonies' (camps) in war-free areas of Spain and in the south of France from war zones during the Spanish Civil War (1936-1939).   In addition to providing a poignant testimony to how children see and understand war, this exhibition reaches out to those who may have been evacuees and provides a way to contact others with memories of that era. The originals of the images displayed here are housed in the Avery Fine Arts and Architectural Library."
        },
		{
			:name => "Chinese Paper Gods",
			:image => 'chinese_paper_gods.jpeg',
			:facet_value => 'Chinese Paper Gods',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio6257012',
			:description => "An online visual catalog of over 200 woodcuts used in folk religious practices in Beijing and other parts of China in the 1930s."
		},
		{
			:name => "Columbia Library Columns",
			:image => 'columns.jpeg',
			:external_url => 'http://library.columbia.edu/locations/rbml/digitalcollections/columns.html',
			:description => "A digitized collection of the journal published by Columbia University Libraries from 1951 to 1996, comprising over 6,900 pages in 46 volumes (135 issues)."
		},
		{
			:name => "Columbia Spectator Archive",
			:image => 'cu_spectator.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio5285428.002',
			:description => "The Archive of the Columbia Daily Spectator, the newspaper of Columbia University, preserves the second-oldest college daily paper in the country. The complete run of the newspaper, from 1877 to 2012, is now available in digital form. The Archive is a public resource for Columbia University history and preserves the Spectator's past work."
		},
		{
			:name => "Community Service Society Photographs",
			:image => 'community_service_society.jpeg',
			:facet_value => 'Community Service Society',
			:external_url => 'http://css.cul.columbia.edu',
			:description => "An online presentation of almost 1400 photographs from the Community Service Society Records at Columbia University's Rare Book & Manuscript Library. They offer representations of pressing social issues in late-19th- and early-20th-century New York."
		},
		{
			:name => "Digital Scriptorium",
			:image => 'digital_scriptorium.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio4091801',
			:description => "The Digital Scriptorium makes available cataloging and selected digital images from medieval and early Renaissance manuscript collections housed in U.S. collections."
		},
		{
			:name => "E-Book Digitization Program",
			:image => 'ebook.jpeg',
			:external_url => 'https://www1.columbia.edu/sec/cu/libraries/bts/ebooks/index.html',
			:description => "Columbia University Libraries has launched a program of selective digitization of pre-1923 books and other items from our collections."
		},
		{
			:name => "G.E.E. Lindquist Native American Photographs",
			:image => 'lindquist.jpeg',
			:facet_value => 'Lindquist Photographs',
			:external_url => 'http://lindquist.cul.columbia.edu',
			:description => "Online presentation of photographs, postcards, negatives, and lantern slides from the G.E.E. Lindquist Papers archival collection at The Burke Library. They depict the people, places, and practices of Native Americans and their communities in the period from 1909-1953."
		},
		{
			:name => "Greene & Greene Architectural Records",
			:image => 'greene.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio4278328',
			:description => "An online collection guide and image database of architectural designs and drawings by Charles Sumner Greene and Henry Mather Greene, architects of the American Arts and Crafts Movement."
		},
		{
			:name => "Historical Corporate Reports",
			:image => 'corporate_reports.jpeg',
			:external_url => 'http://library.columbia.edu/locations/business/corpreports.html',
			:description => "Selected from the collections of Columbia's Watson Library of Business & Economics, this collection presents ca. 770 digitized reports issued between 1850-1960 by some 36 companies, including department stores, utilities, banks, and railroads."
		},
		{
			:name => "Human Rights Web Archive",
			:image => 'hrwa.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10104762.002',
			:description => "The Human Rights Web Archive @ Columbia University is a searchable collection of archived copies of human rights websites created by non-governmental organizations, national human rights institutions, tribunals and individuals. New websites are added to the collection regularly."
		},
        {
            :name => "Jewels in Her Crown: Treasures from the Special Collections of Columbia's Libraries",
            :image => 'jewels_in_her_crown.jpeg',
            :facet_value => 'Jewels in Her Crown',
            :external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio4887511',
            :description => "An online version of the exhibition held in Rare Book and Manuscript Galleries from October 8, 2004 - January 28, 2005, the site brings together for the first time objects selected from all eleven special collections within Columbia University Libraries and affiliates. Mounted in conjunction with the 250th anniversary of Columbia, this exhibition celebrates both the rich collections of books, drawings, manuscripts and other research materials gathered since King's College had its start near Trinity Church in lower Manhattan in 1754 and also the generosity of the donors whose gifts have made possible the work of students and scholars for many generations."
        },
		{
			:name => "John Jay Papers",
			:image => 'john_jay.jpeg',
			:facet_value => 'Jay Papers',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?AVE8231',
			:description => "An online index and text database of correspondence, memos, diaries, etc. written by or to the American statesman John Jay (1745-1829)."
		},
		{
			:name => "Joseph Urban Stage Design Models and Documents",
			:image => 'urban.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio5299290',
			:description => "A virtual collection of high-quality digital images of set models, drawings, documents and more for over 260 New York theater and opera productions."
		},
		{
			:name => "Lehman Papers: Special Correspondence Series",
			:image => 'lehman_papers.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?lweb0107',
			:description => "A searchable database of selected correspondence to and from New York Governor and U.S. Senator Herbert H. Lehman (1878-1963)."
		},
		{
			:name => "Ling Long Women's Magazine",
			:image => 'ling_long.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?ANX0496',
			:description => "A digital version of Ling Long Women's Magazine, originally published in Shanghai from 1931 to 1937 and of significant scholarly research value in several disciplines."
		},
		{
			:name => "New York Real Estate Brochure Collection",
			:image => 'nyre.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio7363386',
			:description => "A searchable database of thousands of advertising brochures, floor plans, price lists, and more from residential and commercial real estate development in New York City and vicinities from the 1920s to the 1970s."
		},
		{
			:name => "Notable New Yorkers",
			:image => 'notable_new_yorkers.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?AH-5AU1DPS05514',
			:description => "Original audio recordings and edited transcripts of oral history interviews with ten influential New Yorkers drawn from the collection of the Columbia Libraries' Columbia Center for Oral History."
		},
		{
			:name => "Real Estate Record and Builders Guide",
			:image => 'real_estate_record.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?rerecord',
			:description => "Digitized volumes of The Real Estate Record and Builders Guide, a magazine detailing building activity in New York City and its environs that began publication in the late 1860s. The project website provides sales, mortgage, conveyance, and other data  as well as illustrated articles on buildings and neighborhood development."
		},
        {
            :name => "Russian Imperial Corps of Pages: an Online Exhibition Catalog",
            :image => 'russian_corps.jpeg',
            :facet_value => 'Russian Corps of Pages',
            :external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio4171223',
            :description => "An online exhibition catalog containing selections from the Columbia University Libraries exhibition, \"The Russian Imperial Corps of Pages,\" on view in Butler Library from December 1, 2002 to February 28, 2003, timed to coincide with celebrations of the 300th anniversary of St. Petersburg.  Objects were drawn from the Imperial Corps of Pages collection held by Columbia's Bakhmeteff Archive of Russian and East European History and Culture, one of the world's most extensive repositories of Russian materials outside Russia."
        },
		{
			:name => "The Tibet Mirror",
			:image => 'tibet_mirror.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio6981643',
			:description => "An online collection of the Tibet Mirror (Tib. Yul phyogs so so'i gsar 'gyur me long), published in Kalimpong, India from 1925 to 1963. Seventy percent of the full run is now available thanks to the generous cooperation of Yale University, Collège de France, and the Musée Guimet."
		},
	]

  def digital_projects
    DIGITAL_PROJECTS
  end

  def get_all_facet_values_and_counts(facet_field_name)
    rsolr = RSolr.connect :url => YAML.load_file('config/solr.yml')[Rails.env]['url']

    values_and_counts = {}

    response = rsolr.get 'select', :params => {
      :q  => '*:*',
      :qt => 'search',
      :rows => 0,
      :facet => true,
      :'facet.sort' => 'index', # We want Solr to order facets based on their type (alphabetically, numerically, etc.)
      :'facet.field' => [facet_field_name],
      ('f.' + facet_field_name + '.facet.limit').to_sym => -1,
    }

    facet_response = response['facet_counts']['facet_fields'][facet_field_name]
    values_and_counts['value_pairs'] = {}
    facet_response.each_slice(2) do |value, count|
      values_and_counts['value_pairs'][value] = count
    end

    return values_and_counts

  end

end
