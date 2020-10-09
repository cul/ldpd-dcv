require 'rails_helper'

describe Dcv::Solr::DocumentAdapter, type: :unit do
	describe Dcv::Solr::DocumentAdapter::Abstract do
		subject { described_class.new(nil) }
		it { is_expected.to respond_to :to_solr }
		it { expect { subject.to_solr }.to raise_error(NotImplementedError) }
	end
end