class SingleObjectFcrApi
	NS = {
		'foxml'=>"info:fedora/fedora-system:def/foxml#",
		'model' => "info:fedora/fedora-system:def/model#",
		'access' => 'http://www.fedora.info/definitions/1/0/access/',
		'xsi'=>"http://www.w3.org/2001/XMLSchema-instance"
	}
	def initialize(foxml)
		@ng_xml = Nokogiri::XML(foxml)
		@pid = @ng_xml.xpath("/foxml:digitalObject/@PID", NS).first
	end
	def repository_profile
		{ 'repositoryVersion' => '3.8.1' }.freeze
	end
	def object_profile(pid, asOfDateTime = nil)
		{
			'objLabel' => object_property('info:fedora/fedora-system:def/model#label'),
			'objOwnerId' => object_property('info:fedora/fedora-system:def/model#ownerId'),
			'objCreateDate' => object_property('info:fedora/fedora-system:def/model#createdDate'),
			'objLastModDate' => object_property('info:fedora/fedora-system:def/view#lastModifiedDate'),
			'objState' => object_property('info:fedora/fedora-system:def/model#state'),
			'objModels' => @ng_xml.xpath("//model:hasModel", NS).map { |modelRef| modelRef['rdf:resource'] }
		}
	end

	def object_property(property_uri)
		property = @ng_xml.xpath("//foxml:property[@NAME='#{property_uri}']").first
		property['VALUE'] if property
	end
	def object_xml(options = {})
		raise NotImplementedError
	end
	def datastream_profile(pid, dsid, validateChecksum, asOfDateTime = nil)
		ds = Nokogiri::XML(datastreams(pid: pid, asOfDateTime: asOfDateTime))
		  .xpath("//access:datastreamProfile[@pid = '#{pid}' and @dsID = '#{dsid}']", NS).first
		return {} unless ds
		Rubydora::ProfileParser.hash_datastream_profile_node(ds)
	end

	def datastreams(args)
		response = <<-XML
<objectDatastreams xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
	xmlns="http://www.fedora.info/definitions/1/0/access/"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
	xsi:schemaLocation="http://www.fedora.info/definitions/1/0/access/ http://www.fedora.info/definitions/1/0/listDatastreams.xsd" 
	pid="donotuse:public" 
	asOfDateTime=""
	baseURL="http://localhost/fedora">
XML
		@ng_xml.xpath("//foxml:datastream", NS).each do |ds|
			response << "<datastreamProfile pid=\"#{@pid}\" dsID=\"#{ds['ID']}\">\n"
			response << "<dsState>#{ds['STATE']}</dsState>"
			response << "<dsControlGroup>#{ds['CONTROL_GROUP']}</dsControlGroup>"
			response << "<dsVersionable>#{ds['VERSIONABLE']}</dsVersionable>"
			response << "<dsInfoType/>"
			ds.xpath("foxml:datastreamVersion", NS).first.tap do |dsVersion|
				response << "<dsVersionID>#{dsVersion['ID']}</dsVersionID>\n"
				response << "<dsCreateDate>#{dsVersion['CREATED'] || object_property('info:fedora/fedora-system:def/model#createdDate')}</dsCreateDate>\n"
				response << "<dsMIME>#{dsVersion['MIMETYPE']}</dsMIME>\n"
				response << "<dsFormatURI>#{dsVersion['FORMAT_URI']}</dsFormatURI>\n"
				response << "<dsSize>#{ds_content_size(dsVersion, ds['CONTROL_GROUP'])}</dsSize>\n"
				response << "<dsLabel>#{dsVersion['LABEL']}</dsLabel>"
				response << "<dsLocation>#{@pid}+#{ds['ID']}+#{dsVersion['ID']}</dsLocation>\n"
			end
			response << "<dsLocationType/>\n"
			response << "<dsChecksumType>DISABLED</dsChecksumType>\n<dsChecksum>none</dsChecksum>\n"
			response << "</datastreamProfile>\n"
		end
		response << "\n</objectDatastreams>"
		response
	end

	def datastream_dissemination(options = {}, &block_response)
		@ng_xml.xpath("//foxml:datastream[@ID='#{options[:dsid]}']/foxml:datastreamVersion", NS).first&.tap do |ds_version|
			ds = ds_version.parent
			control_group = ds['CONTROL_GROUP']
			if control_group == 'X'
				return ds_version.xpath("foxml:xmlContent", NS).first&.inner_html || ""
			elsif control_group == 'M'
				b64_data = ds_version.xpath("foxml:binaryContent", NS).first&.inner_html
				return b64_data ? Base64.decode64(b64_data) : ""
			else
				return ""
			end
		end
	end

	def ds_content_size(ds_version, control_group)
		return ds_version['SIZE'].to_i if ds_version['SIZE']
		datastream_dissemination(dsid: ds_version.parent['ID']).bytesize
	rescue
		puts "ds_content_size('#{ds_version.parent['ID']}:#{ds_version['ID']}', '#{control_group}')"
		raise
	end
end