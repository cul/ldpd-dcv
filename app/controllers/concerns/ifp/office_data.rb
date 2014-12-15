# -*- encoding : utf-8 -*-
module Ifp::OfficeData
  extend ActiveSupport::Concern

  IFP_OFFICE_SIDEBAR_DATA = {
		brazil: {
			:office => "Brazil",
			:browse_digital_records => "Link to DLC-IFP: Brazil",
			:finding_aid => "Link to series IV.1",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3ABrazil",
			:ifp_community => "http://www.fordifp.org/brazil/en-us/home.aspx",
			:ifp_partners => [{ :name => "Carlos Chagas Foundation", :link => "http://www.fcc.org.br" }]
		},
		chile: {
			:office => "Chile",
			:browse_digital_records => "Link to DLC-IFP: Chile",
			:finding_aid => "Link to series IV.2",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AChile",
			:ifp_community => "http://www.fordifp.org/Chile/en-us/home.aspx",
			:ifp_partners => [{ :name => "EQUITAS Foundation", :link => "www.fundacionequitas.org" }],
			:alumni_organization => "www.alumniifpchile.cl"
		},
		china: {
			:office => "China",
			:browse_digital_records => "Link to DLC-IFP: China",
			:finding_aid => "Link to series IV.3",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AChina",
			:ifp_community => "http://www.fordifp.org/China/en-us/home.aspx",
			:ifp_partners => [{ :name => "IIE Beijing Office", :link => "http://www.iiebeijing.org/" }]
		},
		egypt: {
			:office => "Egypt",
			:browse_digital_records => "Link to DLC-IFP: Egypt",
			:finding_aid => "Link to series IV.4",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AEgypt",
			:ifp_community => "http://www.fordifp.org/Egypt/en-us/home.aspx",
			:ifp_partners => [{ :name => "AMIDEAST", :link => "www.amideast.org" }]
		},
		ghana: {
			:office => "Ghana",
			:browse_digital_records => "Link to DLC-IFP: Ghana",
			:finding_aid => "Link to series IV.5",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AGhana",
			:ifp_community => "http://www.fordifp.org/Ghana/en-us/home.aspx",
			:ifp_partners => [{ :name => "Association of African Universities", :link => "www.aau.org" }]
		},
		guatemala: {
			:office => "Guatemala",
			:browse_digital_records => "Link to DLC-IFP: Guatemala",
			:finding_aid => "Link to series IV.6",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AGuatemala",
			:ifp_community => "http://www.fordifp.org/Guatemala/en-us/home.aspx",
			:ifp_partners => [{ :name => "Regional Research Center of Mesoamerica (CIRMA)", :link => "http://cirma.org.gt/" }],
			:alumni_organization => "www.ifpguatemala.org",
		},
		india: {
			:office => "India",
			:browse_digital_records => "Link to DLC-IFP: India",
			:finding_aid => "Link to series IV.7",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AIndia",
			:ifp_community => "http://www.fordifp.org/India/en-us/home.aspx",
			:ifp_partners => [{ :name => "United States India Educational Foundation (USIEF)", :link => "http://www.usief.org.in/" }]
		},
		indonesia: {
			:office => "Indonesia",
			:browse_digital_records => "Link to DLC-IFP: Indonesia",
			:finding_aid => "Link to series IV.8",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AIndonesia",
			:ifp_community => "http://www.fordifp.org/Indonesia/en-us/home.aspx",
			:ifp_partners => [{ :name => "Indonesian International Education Foundation (IIEF)", :link => "www.iief.or.id/" }],
			:alumni_organization => "www.isjn.or.id/",
		},
		kenya: {
			:office => "Kenya",
			:browse_digital_records => "Link to DLC-IFP: Kenya",
			:finding_aid => "Link to series IV.9",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AKenya",
			:ifp_community => "http://www.fordifp.org/Kenya/en-us/home.aspx",
			:ifp_partners => [{ :name => "Forum for African Women Educationalists (FAWE)", :link => "www.fawe.org/" }]
		},
		mexico: {
			:office => "Mexico",
			:browse_digital_records => "Link to DLC-IFP: Mexico",
			:finding_aid => "Link to series IV.10",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AMexico",
			:ifp_community => "http://www.fordifp.org/Mexico/en-us/home.aspx",
			:ifp_partners => [{ :name => "Center for Research and Higher Studies in Social Anthropology (CIESAS)", :link => "www.ciesas.edu.mx" }]
		},
		mozambique: {
			:office => "Mozambique",
			:browse_digital_records => "Link to DLC-IFP: Mozambique",
			:finding_aid => "Link to series IV.11",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AMozambique",
			:ifp_community => "http://www.fordifp.org/Mozambique/en-us/home.aspx",
			:ifp_partners => [{ :name => "Africa-America Institute", :link => "www.aaionline.org/" }]
		},
		nigeria: {
			:office => "Nigeria",
			:browse_digital_records => "Link to DLC-IFP: Nigeria",
			:finding_aid => "Link to series IV.12",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3ANigeria",
			:ifp_community => "http://www.fordifp.org/Nigeria/en-us/home.aspx",
			:ifp_partners => [{ :name => "Association of African Universities", :link => "www.aau.org" }, 
                { :name => "Pathfinder International", :link => "http://www.pathfinder.org/" }]
		},
		palestine: {
			:office => "Palestine",
			:browse_digital_records => "Link to DLC-IFP: Palestine",
			:finding_aid => "Link to series IV.13",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3APalestine",
			:ifp_community => "http://www.fordifp.org/Palestine /en-us/home.aspx",
			:ifp_partners => [{ :name => "AMIDEAST", :link => "www.amideast.org/" }]
		},
		peru: {
			:office => "Peru",
			:browse_digital_records => "Link to DLC-IFP: Peru",
			:finding_aid => "Link to series IV.15",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3APeru",
			:ifp_community => "http://www.fordifp.org/Peru/en-us/home.aspx",
			:ifp_partners => [ { :name => "EQUITAS Foundation", :link => "www.fundacionequitas.org/" },
			    { :name => "Institute of Peruvian Studies (IEP)", :link => "www.iep.org.pe/" } ],
			:alumni_organization => "http://www.alumnifordperu.org",
		},
		philippines: {
			:office => "Philippines",
			:browse_digital_records => "Link to DLC-IFP: Philippines",
			:finding_aid => "Link to series IV.14",
			:ifp_community => "http://www.fordifp.org/Philippines/en-us/home.aspx",
			:ifp_partners => [{ :name => "The Philippine Social Science Council (PSSC)", :link => "www.pssc.org.ph" }]
		},
		russia: {
			:office => "Russia",
			:browse_digital_records => "Link to DLC-IFP: Russia",
			:finding_aid => "Link to series IV.16",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3ARussia",
			:ifp_community => "http://www.fordifp.org/Russia/en-us/home.aspx",
			:ifp_partners => [{ :name => "IIE Moscow Office", :link => "www.iie.org/Offices/Moscow" }]
		},
		senegal: {
			:office => "Senegal",
			:browse_digital_records => "Link to DLC-IFP: Senegal",
			:finding_aid => "Link to series IV.17",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3ASenegal",
			:ifp_community => "http://www.fordifp.org/Senegal/en-us/home.aspx",
			:ifp_partners => [{ :name => "Association of African Universities", :link => "www.aau.org" }, 
                { :name => "West African Research Center (WARC)", :link => "www.warccroa.org" }]
		},
		southafrica: {
			:office => "South Africa",
			:browse_digital_records => "Link to DLC-IFP: South Africa",
			:finding_aid => "Link to series IV.18",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3ASouth Africa",
			:ifp_community => "http://www.fordifp.org/South Africa/en-us/home.aspx",
			:ifp_partners => [{ :name => "Africa-America Institute", :link => "www.aaionline.org/," }]
		},
		tanzania: {
			:office => "Tanzania",
			:browse_digital_records => "Link to DLC-IFP: Tanzania",
			:finding_aid => "Link to series IV.19",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3ATanzania",
			:ifp_community => "http://www.fordifp.org/Tanzania/en-us/home.aspx",
			:ifp_partners => [{ :name => "Economic and Social Research Foundation", :link => "www.esrftz.org" }],
			:alumni_organization => "http://www.ifponline.org/tabid/135/cid/Tanzania/default.aspx",
		},
		thailand: {
			:office => "Thailand",
			:browse_digital_records => "Link to DLC-IFP: Thailand",
			:finding_aid => "Link to series IV.20",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AThailand",
			:ifp_community => "http://www.fordifp.org/Thailand/en-us/home.aspx",
			:ifp_partners => [{ :name => "Asian Scholarship Foundation", :link => "www.asianscholarship.org" }]
		},
		uganda: {
			:office => "Uganda",
			:browse_digital_records => "Link to DLC-IFP: Uganda",
			:finding_aid => "Link to series IV.21",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AUganda",
			:ifp_community => "http://www.fordifp.org/Uganda/en-us/home.aspx",
			:ifp_partners => [{ :name => "Association for Higher Education Advancement & Development (AHEAD)", :link => "http://ahead.or.ug/" }]
		},
		vietnam: {
			:office => "Vietnam",
			:browse_digital_records => "Link to DLC-IFP: Vietnam",
			:finding_aid => "Link to series IV.22",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program&fc=meta_Coverage%3AVietnam",
			:ifp_community => "http://www.fordifp.org/Vietnam/en-us/home.aspx",
			:ifp_partners => [{ :name => "Center for Educational Exchange with Viet Nam (CEEVN)", :link => "http://ceevn.acls.org/" }]
		},
		global: {
			:office => "GLOBAL",
			:browse_digital_records => "Link to DLC-IFP",
			:finding_aid => "Link to F. Aid",
			:web_archive => "https://archive-it.org/collections/2766;?fc=websiteGroup%3AFord+Foundation+International+Fellowship+Program",
			:ifp_community => "http://www.fordifp.org/",
			:ifp_partners => { :name => "Institute for International Education", :link => "www.iie.org" }
		}
	}

  def ifp_office_sidebar_data
    IFP_OFFICE_SIDEBAR_DATA
  end

end
