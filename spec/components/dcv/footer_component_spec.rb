# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dcv::FooterComponent, type: :component do
  subject(:component) { described_class.new(subsite: subsite, repository_id: repository_id) }

  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:site_slug) { 'test' }
  let(:site_repository_id) { nil }
  let(:subsite) { instance_double(Site, slug: site_slug, repository_id: site_repository_id) }
  let(:repository_id) { nil }

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(controller).to receive(:view_context).and_return(view_context)
  end

  context 'has a subsite' do
    it "falls back to NNC when nothing is a variant" do
      expect(rendered).to have_selector("strong", text: "Columbia University Libraries")
    end
    context "with a site repository variant" do
      let(:site_repository_id) { "nynycbl" }
      it "uses the variant indicated by the attribute" do
        expect(rendered).to have_selector("strong", text: "Burke Library at Union Theological Seminary")
      end
    end
    context "with a repository id param" do
      let(:repository_id) { "nnc-a" }
      it "uses the variant indicated by the param" do
        expect(rendered).to have_selector("strong", text: "Avery Architectural & Fine Arts Library")
      end
    end
  end
  context 'has neither subsite nor param' do
    let(:subsite) { nil }
    it "falls back to NNC when nothing is a variant" do
      expect(rendered).to have_selector("strong", text: "Columbia University Libraries")
    end
  end
  describe 'rendering known variants' do
    shared_examples 'a functional footer component' do
      it "renders successfully" do
        expect(rendered).to have_selector("footer")
      end
    end
    context "for the durst subsite" do
      let(:site_slug) { 'durst' }
      it_behaves_like 'a functional footer component'
    end
    context "for the universityseminars subsite" do
      let(:site_slug) { 'universityseminars' }
      it_behaves_like 'a functional footer component'
    end
    context "for the NNC repository" do
      let(:repository_id) { 'nnc' }
      it_behaves_like 'a functional footer component'
    end
    context "for the NNC-A repository" do
      let(:repository_id) { 'nnca' }
      it_behaves_like 'a functional footer component'
    end
    context "for the NNC-EA repository" do
      let(:repository_id) { 'nncea' }
      it_behaves_like 'a functional footer component'
    end
    context "for the NNC-RB repository" do
      let(:repository_id) { 'nncrb' }
      it_behaves_like 'a functional footer component'
    end
    context "for the NyNyCAP repository" do
      let(:repository_id) { 'nynycap' }
      it_behaves_like 'a functional footer component'
    end
    context "for the NyNyCBL repository" do
      let(:repository_id) { 'nynycbl' }
      it_behaves_like 'a functional footer component'
    end
    context "for the NyNyCMA repository" do
      let(:repository_id) { 'nynycma' }
      it_behaves_like 'a functional footer component'
    end
    context "for the NyNyCOH repository" do
      let(:repository_id) { 'nynycma' }
      it_behaves_like 'a functional footer component'
    end
  end
end