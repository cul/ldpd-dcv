require File.expand_path(File.dirname(__FILE__) + '/../../../../rails_helper')

describe "Cul::Hydra::Datastreams::StructMetadata", type: :unit do

  before(:all) do

  end
  let(:mock_inner) { double('inner object') }
  let(:mock_repo) { double('repository') }
  let(:mock_ds) { double('datastream') }
  let(:rv_fixture) { fixture( File.join("struct_map", "structmap-recto.xml")).read }
  let(:rv_doc) { Nokogiri::XML::Document.parse(rv_fixture) }
  let(:struct_fixture) { structMetadata(mock_inner, rv_fixture) }
  let(:seq_fixture) { fixture( File.join("struct_map", "structmap-seq.xml")).read }
  let(:seq_doc) { Nokogiri::XML::Document.parse(seq_fixture) }
  let(:unlabeled_seq_fixture) { fixture( File.join("struct_map", "structmap-unlabeled-seq.xml")).read }
  let(:unordered_seq_fixture) { fixture( File.join("struct_map", "structmap-unordered-seq.xml")).read }
  let(:nested_seq_fixture) { fixture( File.join("struct_map", "structmap-nested.xml")).read }
  before(:each) do
    allow(mock_inner).to receive(:new_record?).and_return(false)
    allow(mock_repo).to receive(:config).and_return({})
    allow(mock_repo).to receive(:datastream_profile).and_return({})
    allow(mock_inner).to receive(:repository).and_return(mock_repo)
    allow(mock_inner).to receive(:pid)
  end

  describe ".new " do
    it "should create a new DS when no structMetadata exists" do
      allow(mock_repo).to receive(:datastream_profile).and_return({})
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(mock_inner, 'structMetadata')
      # it should have the default content
      expect(test_obj.ng_xml).to be_equivalent_to Cul::Hydra::Datastreams::StructMetadata.xml_template
      # but it shouldn't be "saveable" until you do something
      expect(test_obj.new?).to be_truthy
      expect(test_obj.changed?).to be_falsey
      # like assigning an attribute value
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(mock_inner,
       'structMetadata', :label=>'TEST LABEL')
      expect(test_obj.new?).to be_truthy
      expect(test_obj.changed?).to be_truthy
    end
  end

  describe ".create_div_node " do
	  it "should build a simple R/V structure" do
	  	built = Cul::Hydra::Datastreams::StructMetadata.new(nil, 'structMetadata', label:'Sides', type:'physical')
	  	built.create_div_node(nil, {:order=>"1", :label=>"Recto", :contentids=>"rbml_css_0702r"})
	  	built.create_div_node(nil, {:order=>"2", :label=>"Verso", :contentids=>"rbml_css_0702v"})
	  	expect(built.ng_xml).to be_equivalent_to(rv_doc)
	  end

    it "should build a simple sequence structure" do
      built = Cul::Hydra::Datastreams::StructMetadata.new(nil, 'structMetadata', label:'Sequence', type:'logical')
      built.create_div_node(nil, {:order=>"1", :label=>"Item 1", :contentids=>"prd.custord.060108.001"})
      built.create_div_node(nil, {:order=>"2", :label=>"Item 2", :contentids=>"prd.custord.060108.002"})
      built.create_div_node(nil, {:order=>"3", :label=>"Item 3", :contentids=>"prd.custord.060108.003"})
      expect(built.ng_xml).to be_equivalent_to(seq_doc)
    end

    it "should work if the parent node has its own NS prefix" do
      test_src = "<foo:structMap xmlns:foo=\"http://www.loc.gov/METS/\" />"
      test_obj = Cul::Hydra::Datastreams::StructMetadata.from_xml test_src
      test_div = test_obj.create_div_node
      expect(test_div.namespace.prefix).to eql "foo"
    end

    it "should work if the parent node is in the default NS" do
      test_src = "<structMap xmlns=\"http://www.loc.gov/METS/\" />"
      test_obj = Cul::Hydra::Datastreams::StructMetadata.from_xml test_src
      test_div = test_obj.create_div_node
      expect(test_div.namespace.prefix).to be_nil
    end
  end

  describe ".content= " do
    it "should parse existing structMetadata content appropriately" do
      allow(mock_repo).to receive(:datastream_profile).and_return({:dsID => 'structMetadata'})
      allow(mock_repo).to receive(:datastream_dissemination).and_return(rv_fixture)
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(mock_inner, 'structMetadata')
      expect(test_obj.ng_xml).to be_equivalent_to(rv_doc)
    end

    it "should replace existing structMetadata content from setter" do
      allow(mock_repo).to receive(:datastream_profile).and_return({:dsID => 'structMetadata'})
      allow(mock_repo).to receive(:datastream_dissemination).and_return(rv_fixture)
  	  test_obj = Cul::Hydra::Datastreams::StructMetadata.new(mock_inner, 'structMetadata')
      expect(test_obj.ng_xml).to be_equivalent_to(rv_doc)
      test_obj.content= seq_fixture
      expect(test_obj.ng_xml).to be_equivalent_to(seq_doc)
    end
  end

  describe ".serialize! " do
    it "should signal changes to ng_xml" do
      allow(mock_repo).to receive(:datastream_profile).and_return({:dsID => 'structMetadata'})
      allow(mock_repo).to receive(:datastream_dissemination).and_return(rv_fixture)
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(mock_inner, 'structMetadata')
      expected = Nokogiri::XML::Document.parse(rv_fixture.sub(/Sides/,'sediS'))
      test_obj.label = 'sediS'
      test_obj.serialize!
      expect(test_obj.changed?).to be_truthy
      expect(Nokogiri::XML::Document.parse(test_obj.content)).to be_equivalent_to(expected)
    end
  end

  describe "Recto/Verso convenince methods" do
    it "should act otherwise identically to building with .create_div_node" do
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(nil, 'structMetadata', label:'Sides', type:'physical')
      test_obj.recto_verso!
      test_obj.recto['CONTENTIDS']="rbml_css_0702r"
      test_obj.verso['CONTENTIDS']="rbml_css_0702v"
      expect(test_obj.ng_xml).to be_equivalent_to(rv_doc)
      expect(test_obj.changed?).to be_truthy
    end

    it "should not change content unnecessarily" do
      allow(mock_repo).to receive(:datastream_profile).and_return({:dsID => 'structMetadata'})
      allow(mock_repo).to receive(:datastream_dissemination).and_return(rv_fixture)
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(mock_inner, 'structMetadata')
      expect(test_obj.changed?).to be_falsey
      test_obj.recto_verso!
      expect(test_obj.changed?).to be_falsey
    end
  end

  describe "Retrieving data from a structmap" do
		it "should be able to retrieve divs with a CONTENTIDS attribute" do
			struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(seq_fixture)
			divs_with_contentids_attr = struct.divs_with_attribute(true, 'CONTENTIDS')
			expect(divs_with_contentids_attr.length).to eql 3
		end
		it "should be able to retrieve the first ordered content div (where ORDER=\"1\"), regardless of div order" do
			struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(unordered_seq_fixture)
			divs_with_contentids_attr = struct.first_ordered_content_div
			expect(divs_with_contentids_attr.attr('ORDER')).to eql '1'
			expect(divs_with_contentids_attr.attr('LABEL')).to eql 'Item 1'
			expect(divs_with_contentids_attr.attr('CONTENTIDS')).to eql 'prd.custord.060108.001'
		end
	end
  describe "Proxies" do
    let(:digital_object) { double('Digital Object') }
    before do
      allow(digital_object).to receive(:pid).and_return('test:0000')
    end
    subject(:proxies) {
      struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(ds_fixture)
      struct.instance_variable_set(:@digital_object, digital_object)
      struct.instance_variable_set(:@dsid, 'structDS')
      struct.proxies
    }
    context "for recto/verso" do
      let(:ds_fixture) { rv_fixture }
      it { expect(proxies.length).to eql 2 }
      describe "index as" do
        let(:solr_docs) { proxies.collect{|x| x.to_solr } }
        it "should be generate solr hashes for all the structure proxies" do
          missing = solr_docs.detect {|x| x['proxyIn_ssi'] != 'info:fedora/test:0000'}
          expect(missing).to be_nil
        end
        it "should identify the proxy index with index" do
          docs = solr_docs.sort {|a,b| a['index_ssi'] <=> b['index_ssi']}
          index_values = docs.collect {|x| x['index_ssi']}
          expect(index_values).to eql ['1','2']
        end
      end
    end
    context "for a flat list" do
      let(:ds_fixture) { unordered_seq_fixture }
      it { expect(proxies.length).to eql 3 }
      describe "index as" do
        let(:solr_docs) { proxies.collect{|x| x.to_solr } }
        it "should be generate solr hashes for all the structure proxies" do
          missing = solr_docs.detect {|x| x['proxyIn_ssi'] != 'info:fedora/test:0000'}
          expect(missing).to be_nil
        end
        it "should identify the proxy index with index" do
          docs = solr_docs.sort {|a,b| a['index_ssi'] <=> b['index_ssi']}
          index_values = docs.collect {|x| x['index_ssi']}
          expect(index_values).to eql ['1','2','3']
        end
      end
    end
    context "for a flat list without labels" do
      let(:ds_fixture) { unlabeled_seq_fixture }
      it { expect(subject.length).to eql 2 }
      describe "index as" do
        let(:solr_docs) { proxies.collect{|x| x.to_solr } }
        it "should generate solr_docs with ids" do
          solr_docs.each {|solr_doc| expect(solr_doc['id']).not_to be_nil}
        end
        it "should be generate solr hashes for all the structure proxies" do
          missing = solr_docs.detect {|x| x['proxyIn_ssi'] != 'info:fedora/test:0000'}
          expect(missing).to be_nil
        end
        it "should identify the proxy index with index" do
          docs = solr_docs.sort {|a,b| a['index_ssi'] <=> b['index_ssi']}
          index_values = docs.collect {|x| x['index_ssi']}
          expect(index_values).to eql ['1','2']
        end
      end
    end
    context "for a nested structure" do
      let(:ds_fixture) { nested_seq_fixture }
      it { expect(proxies.length).to eql 8 }
      describe "index as" do
        let(:solr_docs) { proxies.collect{|x| x.to_solr } }
        it "should generate solr hashes for all the structure proxies with label, proxyIn and proxyFor" do
          docs = solr_docs.detect {|x| x['proxyIn_ssi'] != 'info:fedora/test:0000'}
          expect(docs).to be_nil
          docs = solr_docs.detect {|x| !x['proxyFor_ssi']}
          expect(docs).to be_nil
          docs = solr_docs.detect {|x| !x['label_ssi']}
          expect(docs).to be_nil
        end
        it "should identify the proxy index with index" do
          docs = solr_docs.sort {|a,b| a['index_ssi'] <=> b['index_ssi']}
          index_values = docs.collect {|x| x['index_ssi']}
          expect(index_values).to eql ['1','1','1','1','2','2','2','2']
        end
        it "should create nfo:file proxies for resources" do
          folders = solr_docs.select {|d| d['type_ssim'].include? RDF::NFO[:"#Folder"].to_s}
          files = solr_docs.select {|d| d['type_ssim'].include? RDF::NFO[:"#FileDataObject"].to_s}
          expect(folders.length).to eql 3
          expect(files.length).to eql 5
        end
        it "should set belongsToContainer appropriately" do
          aggs = Hash.new {|h,k| h[k] = []}
          solr_docs.each {|d| aggs[d['belongsToContainer_ssi']] << d['id'] }
          expect(aggs.size).to eql 4
          leaf1 = "info:fedora/test:0000/structDS/Leaf1"
          leaf2 = "info:fedora/test:0000/structDS/Leaf2"
          leaf3 = "info:fedora/test:0000/structDS/Leaf3"
          expect(aggs).to include leaf1
          expect(aggs[leaf1.to_s].length).to eql 2
          expect(aggs).to include leaf2
          expect(aggs[leaf2.to_s].length).to eql 2
          expect(aggs[nil].sort).to eql [leaf1, leaf2, leaf3] # sort order of IDs
          expect(aggs[leaf1].sort).to eql ["#{leaf1}/Recto", "#{leaf1}/Verso"] # sort order of IDs
          expect(aggs[leaf2].sort).to eql ["#{leaf2}/Recto", "#{leaf2}/Verso"] # sort order of IDs
        end
        it "should set isPartOf for all the ancestor segments" do
          proxy = solr_docs.detect{ |d| d['id'].eql? "info:fedora/test:0000/structDS/Leaf1/Verso"}
          expect(proxy['isPartOf_ssim']).to eql ["info:fedora/test:0000/structDS/Leaf1"]
        end
      end
    end
    context "when composing from several sources" do
      let(:source1) do
        src = fixture( File.join("struct_map", "structmap-nested.xml")).read
        Cul::Hydra::Datastreams::StructMetadata.from_xml(src)
      end
      let(:source2) do
        src = fixture( File.join("struct_map", "structmap-nested2.xml")).read
        Cul::Hydra::Datastreams::StructMetadata.from_xml(src)
      end
      let(:combined) do
        Nokogiri::XML(fixture( File.join("struct_map", "structmap-nested3.xml")).read)
      end
      subject(:datastream) do
        ds = Cul::Hydra::Datastreams::StructMetadata.new
        ds.merge(source1, source2)
      end
      it "should be equivalent to the composite source" do
        expect(datastream.ng_xml).to be_equivalent_to(combined)
        expect(datastream.changed?).to be
      end
    end
  end
end
