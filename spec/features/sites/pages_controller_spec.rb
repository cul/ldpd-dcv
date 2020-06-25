require 'rails_helper'

describe ::Sites::PagesController do
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site) { import.run }
	describe '#show' do
		it 'displays expected text' do
			visit("/#{site.slug}/about")
			expect(page).to have_css('li > strong', text: 'Don\'t Repeat Yourself')
		end
	end
end