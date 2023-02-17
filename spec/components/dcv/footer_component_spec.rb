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
      expect(rendered).to have_selector("small", text: "535 West 114th St. New York, NY 10027 \u2022 Telephone (212) 854-7309")
    end
    context "with a site repository variant" do
      let(:site_repository_id) { "nynycoh" }
      it "uses the variant indicated by the attribute" do
        expect(rendered).to have_selector("small", text: "6th Floor East Butler Library \u2022 535 West 114th St.
New York, NY 10027 \u2022 rbml@library.columbia.edu")
      end
    end
    context "with a repository id param" do
      let(:repository_id) { "nnc-a" }
      it "uses the variant indicated by the param" do
        expect(rendered).to have_selector("small", text: "300 Avery Hall \u2022 avery-drawings@columbia.edu")
      end
    end
  end
  context 'has neither subsite nor param' do
    let(:subsite) { nil }
    it "falls back to NNC when nothing is a variant" do
      expect(rendered).to have_selector("small", text: "535 West 114th St. New York, NY 10027 \u2022 Telephone (212) 854-7309")
    end
  end
end