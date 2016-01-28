# -*- encoding : utf-8 -*-
module Dcv::Catalog::BrowseListBehavior
  extend ActiveSupport::Concern

  # Browse list items must be accessible as facets from in solr (i.e. like facets)
  BROWSE_LISTS_KEY_PREFIX = 'browse_lists_'
  BROWSE_LISTS = {
    'lib_name_sim' => {:display_label => 'Names', :short_description => 'People, corporate bodies and events that are represented in or by our items.'},
    'lib_format_sim' => {:display_label => 'Formats', :short_description => 'Original formats of our digitally-presented items.'},
    'lib_repo_long_sim' => {:display_label => 'Library Locations', :short_description => 'Locations of original items:'}
  }

  # Browse List Logic
  
  def browse_lists_cache_key
		return BROWSE_LISTS_KEY_PREFIX + controller_name
	end
  
  def get_browse_lists
		refresh_browse_lists_cache if Rails.env == 'development' || ! Rails.cache.exist?(browse_lists_cache_key)
    return Rails.cache.read(browse_lists_cache_key)
	end

  def refresh_browse_lists_cache
    if Rails.env == 'development' || ! Rails.cache.exist?(browse_lists_cache_key)
      Rails.cache.write(browse_lists_cache_key, generate_browse_lists, expires_in: 24.hours);
    end
    @browse_lists = Rails.cache.read(browse_lists_cache_key)
  end

  def generate_browse_lists
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
			:name => "1968: Columbia in Crisis",
			:image => '1968_columbia_crisis.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio8683372',
			:description => "The occupation of five buildings in April 1968 marked a sea change in the relationships among Columbia University administration, its faculty, its student body, and its neighbors. Featuring original documents, photographs, and audio from the University Archives, this online exhibition examines the causes, actions, and aftermath of a protest that captivated the campus, the nation, and the world."
		},
    {
			:name => "APIS: Advanced Papyrological Information System",
			:image => 'apis.jpeg',
			:external_url => 'http://www.papyri.info/search?DATE_MODE=LOOSE&DOCS_PER_PAGE=15&COLLECTION=columbia',
			:description => "APIS is a component of the larger Papyrological Navigator database, a worldwide aggregation of digital images, metadata, translations and transcriptions of papyri and ostraca (clay tablets).  A listing of Columbia's ca. 5,800 papyri and ostraca can be viewed <a href='http://www.papyri.info/search?DATE_MODE=LOOSE&DOCS_PER_PAGE=15&COLLECTION=columbia'>here</a>."
		},
    {
			:name => "Avery's Architectural Ephemera Collections",
			:image => 'avery_architectural_ephemera.jpeg',
			:facet_value => "Avery’s Architectural Ephemera Collections",
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10813843',
			:description => "Avery Classics is home to one of the largest special collections of rare architectural materials in the world. In addition to books, manuscripts, and photographs, the department includes a significant collection of ephemera. This exhibit describes some of the brochures, pamphlets, advertising materials, postcards, and other forms of architectural ephemera within Avery Classics."
		},
    {
			:name => "Avery's Architectural Novelties",
			:image => 'avery_architectural_novelties.jpg',
			:facet_value => "Avery’s Architectural Novelties",
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9427856',
			:description => "This exhibition highlights a selection of architectural novelties from the Avery Classics collection, displaying items that are both comprehensive and eccentric in their treatment of architecture."
		},
    {
			:name => "Barbara Curtis Adachi Bunraku Collection",
			:image => 'bunraku.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10884995',
			:description => "Bunraku, a highly developed form of puppet theater, is a collaboration between puppeteers, narrators, and musicians. This collection of Bunraku images is one of the most extensive in the world."
		},
    {
			:name => "Barney Rosset and China",
			:image => 'rosset_china.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10657890',
			:description => "The photographs in this exhibit were taken during 1944 and 1945 by Grove Press founder, Barney Rosset, and other colleagues, when he was a photographer in the US Army Signal Corps stationed in China. The photos document U.S. cooperation with Chinese soldiers, the surrender, and Japanese retreat, as well as devastation caused by the fighting. The exhibition also demonstrates Rosset's interest in China preceding this post and afterward in his career as a publisher. The materials come from the Barney Rosset Papers held by the Rare Book and Manuscript Library."
		},
		{
			:name => "Biggert Collection of Architectural Vignettes on Commercial Stationery",
			:image => 'biggert.jpeg',
			:facet_value => 'Biggert Collection',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio7887951',
			:description => "Contains over 1,300 items of printed ephemera with architectural imagery from 1850-1920, spanning more than 350 cities and towns in forty-five states."
		},
		{
			:name => "Books",
			:image => 'ebook.jpeg',
			:external_url => 'http://library.columbia.edu/find/ebooks.html',
			:description => "Columbia's digitized books, including rare and out-of-print content, are available in <a href='http://www.columbia.edu/cgi-bin/cul/resolve?clio8498670'>Hathi Trust</a> and also the <a href='https://archive.org/details/ColumbiaUniversityLibraries'>Internet Archive</a>.  All digitized titles are cataloged and linked in <a href='http://www.columbia.edu/cgi-bin/cul/resolve?clio'>CLIO</a>."
		},
		{
			:name => "Butler 75: Butler Library's 75th Anniversary, 1934-2009",
			:image => 'butler75.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio8586236',
			:description => "In celebration of Butler Library's 75th anniversary, we are pleased to present Butler 75, an online exhibition of Butler Library, 1934 – 2009. The exhibition highlights images from the University Archives highlighting the construction, art and architecture of Butler Library, and the people who've used and enjoyed the library over the years. Special features include a timeline of events and a \"Tell Us Your Story\" area of alumni memories."
		},
		{
			:name => "Caste, Ambedkar, and Contemporary India",
			:image => 'caste_india.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?lweb0137',
			:description => "This exhibit complements the conference, \"Caste and Contemporary India,\" that took place on October 16th and 17th, 2009, at Columbia University in honor of alumnus Dr. B. R. Ambedkar. The exhibit features a sampling of resources on issues of caste with reference to gender, politics, constitutional history, and religion in contemporary India."
		},
		{
			:name => "Chamber of Commerce of New York",
			:image => 'chamber_of_commerce.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio7881999',
			:description => "This exhibit provides a rich visual guide to the New York Chamber of Commerce and Industry Records collection in the Rare Book & Manuscript Library. Organized thematically, it showcases the varied business that occupied the New York Chamber of Commerce over its more than two hundred years of operation."
		},
		{
			:name => "Charles A. Platt's Italian Garden Photographs",
			:image => 'platt_gardens.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?lweb0180',
			:description => "In 1892, Charles A. Platt traveled to Italy with his brother, William, to view Italian Renaissance villas and gardens. Many of the photographs he took were used to illustrate his Italian Gardens (Harper & Brothers, 1894).  The images in this exhibition are from the glass plate negatives held in the Charles A. Platt Collection, Drawings & Archives Collection, Avery Architectural & Fine Arts Library."
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
			:name => "Choosing Sides: Right-Wing Icons in the Group Research Records",
			:image => 'choosing_sides.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio7888001',
			:description => "Group Research was an independent organization that documented and publicized the activities of \"extremist\" political groups in the United States from the early 1960s to the mid-1990s. This exhibit draws from Group Research's archive to showcase the role that visual media played in creating the modern American conservative movement during those years. Included are more than fifty images from items like newsletters, posters, record covers, and bumper stickers that represented such notable right-wing groups as the John Birch Society, the Christian Crusade, and the Citizens' Councils of America."
		},
		{
			:name => "A Church is Born: Church of South India Inauguration",
			:image => 'a_church_is_born.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio11373281',
			:description => "The unification of the Church of South India in September 1947, depicted here through a filmstrip and commentary, is considered one of the most important in the Church Union movement. For the first time after centuries of division, churches with various ministries were brought together in a collective Episcopal Church. The reconciliation it reached between Anglicans and other denominations on the doctrine of apostolic succession is often cited as a landmark in the ecumenical movement. This exhibit depicts not only the road to unification in South India, but also the efforts that the Burke Library at Union Theological Seminary took to trace the history and ownership of the collection, while preserving and making the film available to researchers."
		},
		{
			:name => "Columbia Historical Corporate Reports: Digitized Reports from Watson Library's Collection",
			:image => 'corporate_reports.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10886490',
			:description => "Selected from the collections of Columbia's Watson Library of Business &amp; Economics, this collection presents ca. 770 digitized reports issued between 1850-1960 by some 36 companies, including department stores, utilities, banks, and railroads."
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
			:name => "Comics in the Curriculum",
			:image => 'comics.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio7992131',
			:description => "This exhibition highlights Butler Library's growing collection of comics and graphic novels. The medium of comics encompasses every genre and offers a wide variety of artistic and literary styles. Through seven different themes, the exhibition contrasts traditional art with comic art, and suggests possibilities for use in research and teaching."
		},
		{
			:name => "Community Service Society Photographs",
			:image => 'community_service_society.jpeg',
			:facet_value => 'Community Service Society',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10316120',
			:description => "An online presentation of almost 1400 photographs from the Community Service Society Records at Columbia University's Rare Book &amp; Manuscript Library. They offer representations of pressing social issues in late-19th- and early-20th-century New York."
		},
		{
			:name => "Construction and Evolution of Union Theological Seminary Campus",
			:image => 'construction_and_evolution_uts.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio11612867',
			:description => "This exhibit features images from a small collection of photographs documenting the construction of Union Theological Seminary located in the Morningside Heights neighborhood of New York City. The third location for the Seminary, the buildings were constructed from 1908-1910. The collection is housed at the Burke Library at Union Theological Seminary, Columbia University in the City of New York."
		},
		{
			:name => "Core Curriculum: Contemporary Civilization",
			:image => 'core_curriculum_contemporary_civ.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9124725',
			:description => "This online exhibition and its companion, \"Literature Humanities,\" celebrate the Core as the cornerstone of a Columbia education. Highlights include Galileo's Starry Messenger (1610); John Jay's manuscript of Number 5 of The Federalist Papers (1788); and Mary Wollstonecraft's A Vindication of the Rights of Woman (1792)."
		},
		{
			:name => "Core Curriculum: Literature Humanities",
			:image => 'core_curriculum_literature_humanities.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9124743',
			:description => "A companion to \"Core Curriculum: Contemporary Civilization,\" highlights of this exhibition include a papyrus fragment of Homer’s Iliad dating from the 1st century BCE; a copy of Homer’s Works (1517) owned by Martin Luther; Shakespeare’s first folio Works (1623); and Virginia Woolf’s To the Lighthouse (1926)."
		},
		{
			:name => "Cornelius Vander Starr, His Life and Work",
			:image => 'cornelius_vander_starr.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio11161412',
			:description => "The photographs in this exhibition are in the possession of The Starr Foundation, and show in a nutshell, the career of Cornelius Vander Starr (1892-1968) who was a prototype of the classic American success story.  Starting from humble beginnings he rose to the top in American business, founding what would become the AIG insurance conglomerate.  What made C.V. Starr stand out in his day was that, starting in Shanghai, China, and subsequently around the world, wherever he founded branches of his various companies, he used local talent to run those companies rather than relying on American managers.  Starr’s commitment to scholarship and a better understanding of Asia eventually led to the establishment of The Starr Foundation which, to this day is supporting those same interests."
		},
		{
			:name => "Cuneiform Digital Library Initiative",
			:image => 'cuneiform.jpeg',
			:external_url => 'http://cdli.ucla.edu/collections/columbia/columbia.html',
			:description => "CDLI is an online catalog of more than 230,000 cuneiform tablets with over  75,000 images. Columbia's ca. 500 tablets are included in this collection and may be browsed <a href='http://cdli.ucla.edu/collections/columbia/columbia.html'>here</a>."
		},
		{
			:name => "Digital Scriptorium",
			:image => 'digital_scriptorium.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio4091801',
			:description => "The Digital Scriptorium makes available cataloging and selected digital images from medieval and early Renaissance manuscript collections housed in U.S. collections. It includes images from some 1,442 Columbia manuscripts from the <a href='http://ucblibrary4.berkeley.edu:8088/xtf22/search?rmode=digscript&smode=bid&bid=20&docsPerPage=30'>Rare Books &amp; Manuscript Library</a> and <a href='http://ucblibrary4.berkeley.edu:8088/xtf22/search?rmode=digscript&smode=bid&bid=22&docsPerPage=30'>Burke Library</a>."
		},
		{
			:name => "Dramatic Museum Realia",
			:image => 'dramatic_museum.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio8556788',
			:description => "A website with images and descriptions of over 500 puppets, masks, historical theater models and stage designs.  Gathered for documentary and pedagogical purposes, the objects range in date from the 18th well into the 20th centuries, and are from countries all around the globe."
		},
		{
			:name => "Early Modern Futures",
			:image => 'early_modern_futures.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio11376130',
			:description => "This exhibition accompanies the Early Modern Futures conference held on April 24, 2015 as well as a physical exhibition in the Rare Book & Manuscript Library. Early Modern Futures seeks to spark a conversation about the many ways in which early modern literature practices prospective historical thinking. It asks how beliefs about future events (from the eschatological to the economic to the genealogical) shaped peoples actions in the present; how early modernity analogized historical and prospective thinking; and how various textual and literary forms--whether records, scripts, manuals, genres, or editions--sought to represent the future and even anticipate their own reception."
		},
		{
			:name => "Ford IFP Archive",
			:image => 'IFP-square-logo.png',
			:external_url => 'https://dlc.library.columbia.edu/ifp',
			:description => "The archives cover the issues of social justice, community development, and access to higher education, and include paper and digital documentation and audiovisual materials on the more than 4,300 IFP Fellows as well as comprehensive planning and administrative files of the program."
		},
		{
			:name => "Frances Perkins: The Woman Behind the New Deal",
			:image => 'frances_perkins.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?lweb0136',
			:description => "Frances Perkins (1880-1965) is no longer a household name, yet she was one of the most influential women of the twentieth century. Government official for New York State and the federal government, including Industrial Commissioner of the State of New York from 1929-1932, Perkins was named Secretary of Labor by Franklin Delano Roosevelt in 1933. As FDR's friend and ally, Perkins would help the president fight the economic ravages caused by the Great Depression and make great strides toward improving workplace conditions."
		},
		{
			:name => "G.E.E. Lindquist Native American Photographs",
			:image => 'lindquist.jpeg',
			:facet_value => 'Lindquist Photographs',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9616891',
			:description => "Photographs, postcards, negatives, and lantern slides from the G.E.E. Lindquist Papers archival collection at The Burke Library. They depict the people, places, and practices of Native Americans and their communities from 1909-1953."
		},
		{
			:name => "Greene & Greene Architectural Records and Papers Collection",
			:image => 'greene.jpeg',
			:facet_value => 'Greene & Greene',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio4278328',
			:description => "An online collection guide and image database of architectural designs and drawings by Charles Sumner Greene and Henry Mather Greene, architects of the American Arts and Crafts Movement."
		},
		{
			:name => "Hugh Ferriss Architectural Drawings and Papers Collection",
			:image => 'ferriss.jpeg',
			:facet_value => 'Hugh Ferriss Architectural Drawings',
			:external_url => 'http://library.columbia.edu/locations/avery/da/collections/ferriss.html',
			:description => "This collection was donated to Avery Library by his family after Ferriss' death, and has been supplemented by several later additions from other sources. All 363 original drawings in the collection have been photographed and digitized."
		},
		{
			:name => "Human Rights Web Archive",
			:image => 'hrwa.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10104762.002',
			:description => "The Human Rights Web Archive @ Columbia University is a searchable collection of archived copies of human rights websites created by non-governmental organizations, national human rights institutions, tribunals and individuals. New websites are added to the collection regularly."
		},
		{
			:name => "Iconography of Manhattan Island: Illustrations from the Publication",
			:image => 'stokes_iconography.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?lweb0138',
			:description => "Images from Columbia University Libraries 2008 electronic publication of: Stokes, I. N. Phelps. The iconography of Manhattan Island, 1498-1909. Vols. 1-6. New York : Robert H. Dodd, 1915-1928."
		},
		{
			:name => "Jewels in Her Crown: Treasures from the Special Collections of Columbia's Libraries",
			:image => 'jewels_in_her_crown.jpeg',
			:facet_value => 'Jewels in Her Crown',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio4887511',
			:description => "An online version of the exhibition held in Rare Book and Manuscript Galleries from October 8, 2004 - January 28, 2005, the site brings together for the first time objects selected from all eleven special collections within Columbia University Libraries and affiliates. Mounted in conjunction with the 250th anniversary of Columbia, this exhibition celebrates both the rich collections of books, drawings, manuscripts and other research materials gathered since King's College had its start near Trinity Church in lower Manhattan in 1754 and also the generosity of the donors whose gifts have made possible the work of students and scholars for many generations."
		},
		{
			:name => "John H. Yardley Collection of Architectural Letterheads",
			:image => 'yardley.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10976901',
			:description => "This collection provides a unique view of New York City's evolution during the 19th and 20th centuries. Selected for their illustrations of buildings in lower Manhattan, these pieces of stationery include rare images of the city's commercial architecture, much of which is no longer extant."
		},
		{
			:name => "Joseph Pulitzer and The World",
			:image => 'joseph_pulitzer.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9225138',
			:description => "An exhibition of the papers of Joseph Pulitzer and of his newspaper, The World, held by the Rare Book & Manuscript Library. The exhibition contains a variety of materials that show the working life of this truly remarkable individual. Included are letters, documents, ledgers, newspapers, photographs, and realia concerning his life, as well as material documenting Pulitzer's role in the founding of Columbia's School of Journalism and the creation of the Pulitzer Prizes."
		},
		{
			:name => "Joseph Urban Stage Design Models and Documents",
			:image => 'urban.jpeg',
			:facet_value => 'Urban Stage Design',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio5299290',
			:description => "A virtual collection of high-quality digital images of set models, drawings, documents and more for over 260 New York theater and opera productions."
		},
		{
			:name => "Judging a Book by its Cover: Gold Stamped Publishers' Bindings of the 19th Century",
			:image => 'judging_a_book.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio8235351',
			:description => "Since the invention of printing by movable type in the fifteenth century, books had been issued in folded-and-gathered printed sheets which the buyer then had bound to order. In the early nineteenth century, the development of case binding, a technique conducive to mass production, at last made possible the manufacture of books with uniform edition bindings. The advent of gold-stamped decoration, circa 1832, was the most important factor in the acceptance of publishers' bindings."
		},
		{
			:name => "Korean Independence Outbreak Movement",
			:image => 'korean_independence.jpg',
			:facet_value => 'Korean Independence',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio7688161',
			:description => "Commonly referred to as the Samil Movement (literally \"three one\") for its historical date on March 1, 1919, the Korean Independence Movement was one of the earliest and most significant displays of nonviolent demonstration against Japanese rule in Korea."
		},
		{
			:name => "Lehman Special Correspondence Files",
			:image => 'lehman_papers.jpeg',
			:facet_value => 'Lehman Correspondence',
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
			:name => "Melting Pot: Russian Jewish New York",
			:image => 'melting_pot.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio8012143',
			:description => "An online exhibition of materials from the Bakhmeteff Archive of Russian and East European History and Culture exhibition held at the Rare Book and Manuscript Library from April 4, 2006 to July 30, 2006. It features photographs, personal documents, posters, original artworks, and books on the New York Russian Jewish immigrant community."
		},
		{
			:name => "Music at Columbia: the First 100 Years",
			:image => 'music_at_columbia.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9628664',
			:description => "The online version of the 1996 Centennial Exhibition of Columbia's Department of Music, mounted in Low Library as part of the Department's celebrations, with material drawn from the University Archives, Rare Book and Manuscript Library, Music Library, and Office of Art Properties."
		},
		{
			:name => "Naked Lunch: The First Fifty Years",
			:image => 'naked_lunch.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?lweb0139',
			:description => "The exhibition celebrates the 50th anniversary of William S. Burroughs's novel Naked Lunch and provides an overview of Columbia University's extensive holdings of rare books and original manuscripts related to the novel's creation, composition, and editing, as well as other unique Burroughs material. The exhibition includes the original manuscripts of Burroughs's first two novels, Junkie (1953) and Naked Lunch (1959), and correspondence to and from Burroughs, and his close friends and collaborators Lucien Carr, Allen Ginsberg, and Jack Kerouac, as well as photographs, and Burroughs's own Dream Machine."
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
			:name => "Our Tools of Learning: George Arthur Plimpton's Gifts to Columbia University",
			:image => 'plimpton.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?lweb0116',
			:description => "Drawn exclusively from the Plimpton Collection, this exhibition includes manuscripts and books from medieval times through the early 20th century, including many of the manuscripts and books that were used to illustrate George Arthur Plimpton's The Education of Shakespeare and The Education of Chaucer, and David Eugene Smith's Rara Arithmetica. Additional sections of the exhibition deal with handwriting and education for women, two of Plimpton's particular interests."
		},
		{
			:name => "Papers of John Jay",
			:image => 'john_jay.jpeg',
			:facet_value => 'Jay Papers',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?AVE8231',
			:description => "An online index and text database of correspondence, memos, diaries, etc. written by or to the American statesman John Jay (1745-1829)."
		},
		{
			:name => "People in the Books: Hebraica and Judaica Manuscripts from Columbia University Libraries",
			:image => 'people_in_the_books.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9680681',
			:description => "Columbia's collection of Judaica and Hebraica is the third largest in the country, and the largest of any non-religious institution. This is an online version of an exhibition held at the Rare Book & Manuscript Library from Sept. 12, 2012 through Jan. 25, 2013. The exhibit features highlights from the collection, spanning the 10th to the 20th centuries, and crossing the globe from India to the Caribbean. The exhibit focuses on the many stories inherent in each of the manuscripts."
		},
		{
			:name => "Photographs from the Community Service Society Records, 1900-1920",
			:image => 'photographs_from_css.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9124689',
			:description => "An exhibit of photographs (by Jessie Tarbox Beals, Lewis Hine, and others) and publications used in the \"scientific charity\" movement by the Association for Improving the Condition of the Poor, founded in 1843, and the New York Charity Organization Society, founded in 1882, which are today merged and known as the Community Service Society (CSS). Their innovative methods were later incorporated into the practices of social work, government welfare programs, and philanthropic organizations."
		},
		{
			:name => "Political Ecologies in the Renaissance",
			:image => 'political_ecologies.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio8626724',
			:description => "This exhibition brings together eleven scientific texts from Columbia's Rare Book and Manuscript Library. It features canonical and non-canonical science books and covers seven topics: mining, magnetism, navigation, astronomy, the art of war, hydraulics and hydrostatics, and astrology."
		},
		{
			:name => "Quran in East and West: Manuscripts and Printed Books",
			:image => 'quran_in_east_and_west.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10216814',
			:description => "The online adaptation of a 2005 exhibition showcases a wide range of holdings concerning Islam in the Burke Library at Union Theological Seminary. The exhibition highlights Burke's collection of Qurans, while exploring Christian perceptions of Islam and the Quran between 1500 and 1900."
		},
		{
			:name => "Reading of Books and the Reading of Literature",
			:image => 'reading_of_books.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9399444',
			:description => "This online exhibition is meant to accompany a day-long symposium at Columbia University on April 27, 2012. The exhibition, along with the conference, focuses on the relation between literature and the media in which it is conveyed."
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
			:description => "An online exhibition catalog containing selections from the Columbia University Libraries exhibition, \"The Russian Imperial Corps of Pages,\" on view in Butler Library from December 1, 2002 to February 28, 2003, timed to coincide with celebrations of the 300th anniversary of St. Petersburg.  Objects were drawn from the Imperial Corps of Pages collection held by Columbia's <a href='http://library.columbia.edu/locations/rbml/units/bakhmeteff.html'>Bakhmeteff Archive of Russian and East European History and Culture</a>, one of the world's most extensive repositories of Russian materials outside Russia."
		},
		{
			:name => "Sergei Diaghilev and Beyond: Les Ballets Russes",
			:image => 'diaghilev_and_beyond.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10379406',
			:description => "The diversity and splendor of Sergei Diaghilev's world of Russian ballet and opera seasons in Paris was on display at the Chang Octagon Exhibition Room, Rare Book & Manuscript Library, March 16 through June 26, 2009. The exhibition features selections from the Bakhmeteff Archive and Rare Book and Manuscript Library collections."
		},
		{
			:name => "Seymour B. Durst Old York Library",
			:image => 'durst.jpg',
			:external_url => 'https://dlc.library.columbia.edu/durst',
			:description => "The Seymour B. Durst Old York Library collection at the Avery Architectural & Fine Arts Library consists of more than 40,000 objects including historic photographs, maps, pamphlets, postcards, books, and New York City memorabilia from the 18th century to the 1980s."
		},
		{
			:name => "Shakespeare and the Book",
			:image => 'shakespeare.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio8767211',
			:description => "An online version of the exhibition held in the Kempner Gallery of the Rare Book & Manuscript Library from December 6, 2001 through March 11, 2002, inspired by the publication of David Scott Kastan's Shakespeare & The Book (Cambridge University Press, September, 2001). It includes images of Columbia's copy of Shakespeare first folio (1623) as well as Columbia's copies of the other three 17th century Shakespeare folios."
		},
		{
			:name => "Stonewall and Beyond: Lesbian and Gay Culture",
			:image => 'stonewall_and_beyond.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?AUZ6592',
			:description => "The online edition of a Columbia University Libraries general exhibition on gay and lesbian history and culture, held from May 25 to September 17, 1994 in conjunction with the international celebration of the twenty-fifth anniversary of the \"Stonewall Riots\" in New York City."
		},
		{
			:name => "Sydney Howard Gay's \"Record of Fugitives\"",
			:image => 'record_of_fugitives.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio11223783',
			:description => "In 1855 and 1856, Sydney Howard Gay, a key operative in the underground railroad in New York City, decided for unknown reasons to meticulously record the arrival of fugitive slaves at his office.  The resulting two volumes are a treasure trove of information about how and why slaves escaped, who assisted them, and where they were sent from New York. This website explores this important artifact in detail, displaying the journals in their entirety, and offering additional annotations and analytical commentary by Eric Foner, DeWitt Clinton Professor of History at Columbia University."
		},
		{
			:name => "Tibet Mirror",
			:image => 'tibet_mirror.jpeg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio6981643',
			:description => "An online collection of the Tibet Mirror (Tib. Yul phyogs so so'i gsar 'gyur me long), published in Kalimpong, India from 1925 to 1963. Seventy percent of the full run is now available thanks to the generous cooperation of Yale University, Collège de France, and the Musée Guimet."
		},

		{
			:name => "Type to Print: the Book & the Type Specimen Book",
			:image => 'type_to_print.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10450214',
			:description => "An online companion to an exhibit celebrating the 60th anniversary of the American Type Founders collection at the Rare Book & Manuscript Library, Columbia University."
		},
		{
			:name => "Ulysses Kay: Twentieth Century Composer",
			:image => 'ulysses_kay.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10228336',
			:description => "Ulysses Kay (1917-1995) wrote more than one hundred forty compositions in a wide range of forms – five operas, over two dozen large orchestral works, more than fifty voice or choral compositions, over twenty chamber works, a ballet, and numerous other compositions for voice, solo instruments or dancer, film, and television."
		},
		{
			:name => "Unwritten History: Alexander Gumby's African America",
			:image => 'alexander_gumby.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio9008767',
			:description => "This exhibit explores the efforts of Alexander Gumby to create a documentary history of African-American achievement in the nineteenth and early-twentieth centuries. An influential figure during the Harlem Renaissance, Gumby compiled a scrapbook collection of approximately 300 volumes in support of his project, filled with news clippings, photographs, pamphlets, handbills, original artwork, manuscripts, and ephemera, pages from which are on display here."
		},
		{
			:name => "Varsity Show: A Columbia Tradition",
			:image => 'varsity_show.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio8225262',
			:description => "Initially conceived as a fundraiser for the University's athletics teams, The Varsity Show has grown into Columbia University's oldest performing arts tradition. This online exhibition, highlighting the history and some of the more notable elements of this tradition, is an expansion of a physical exhibit created by the University Archives in 2004 to mark the 110th anniversary of The Varsity Show."
		},
		{
			:name => "Wilbert Webster White Papers",
			:image => 'white_papers.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio7665773',
			:description => "Dr. Wilbert Webster White was the founder in 1900 and President, 1900-1939, of Bible Teachers' College, now New York Theological Seminary. He was renowned for his development of an inductive system of Bible Study, emphasizing knowledge of the Bible rather than knowledge about the Bible. His Papers contain an Address by him on the Biblio-centric Curriculum. Dr. White's papers, along with the records of Biblical Seminary and New York Theological Seminary, now form part of The Burke Library Archives (Columbia University Libraries) and present a remarkable resource for researchers."
		},
		{
			:name => "WWI Pamphlets 1913-1920",
			:image => 'wwi_pamphlets.jpg',
			:external_url => 'http://www.columbia.edu/cgi-bin/cul/resolve?clio10796153',
			:description => "A collection of World War I pamphlets from Columbia University Libraries."
		},
	]

  def digital_projects
    DIGITAL_PROJECTS
  end

  def get_all_facet_values_and_counts(facet_field_name)
    rsolr = RSolr.connect :url => YAML.load_file('config/solr.yml')[Rails.env]['url']

    values_and_counts = {}

    response = rsolr.get 'select', :params => self.blacklight_config.default_solr_params.merge({
      :q  => '*:*',
      :rows => 0,
      :'facet.sort' => 'index', # We want Solr to order facets based on their type (alphabetically, numerically, etc.)
      :'facet.field' => [facet_field_name],
      ('f.' + facet_field_name + '.facet.limit').to_sym => -1,
    })

    facet_response = response['facet_counts']['facet_fields'][facet_field_name]
    values_and_counts['value_pairs'] = {}
    facet_response.each_slice(2) do |value, count|
      values_and_counts['value_pairs'][value] = count
    end

    return values_and_counts

  end

end
