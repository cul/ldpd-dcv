require 'rails_helper'

describe Dcv::TextTruncateHelper, :type => :helper do
  describe '#collapsible_span_id' do
    let(:doc_id) { 'cul:rr4xgxd48j' }
    let(:field) { 'lib_public_note_(references)_notes_ssm' }
    let(:ix) { 0 }
    let(:expected) { 'cul_rr4xgxd48j-lib_public_note__references__notes_ssm-collapse-0' }
    subject(:actual) { helper.collapsible_span_id(doc_id, field, ix) }
  	it { is_expected.to eql(expected) }
  end
end