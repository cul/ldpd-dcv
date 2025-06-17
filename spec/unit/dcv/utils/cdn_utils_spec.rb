require 'rails_helper'

describe Dcv::Utils::CdnUtils, type: :unit do
  describe '.file_uri_ds_location_to_file_path' do
    let(:file_path) { '/path/to/a & b.mp4' }
    let(:url_encoded_file_path) { file_path.gsub(' ', '%20').gsub('&', '%26') }
    let(:single_slash_file_uri) { "file:#{url_encoded_file_path}" }
    let(:triple_slash_file_uri) { "file://#{url_encoded_file_path}" }

    it 'properly converts a ds location that uses a single slash file URI' do
      expect(described_class.file_uri_ds_location_to_file_path(single_slash_file_uri)).to eq(file_path)
    end

    it 'properly converts a ds location that uses a triple slash file URI' do
      expect(described_class.file_uri_ds_location_to_file_path(triple_slash_file_uri)).to eq(file_path)
    end

    describe '.info_url' do
      let(:test_url) { 'http://test.org' }
      let(:image_id) { 'image:1' }
      let(:expected) { "#{test_url}/iiif/2/standard/#{image_id}/info.json" }
      before do
        allow(Dcv::Utils::CdnUtils).to receive(:random_cdn_url).and_return(test_url)
      end
      it 'properly generates a triclops-friendly info.json' do
        expect(described_class.info_url(id: image_id)).to eql(expected)
      end
    end
  end
end
