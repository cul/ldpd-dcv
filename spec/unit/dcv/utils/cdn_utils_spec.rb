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
  end
end
