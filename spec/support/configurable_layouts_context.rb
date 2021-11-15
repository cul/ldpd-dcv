shared_context "verify configurable layouts", shared_context: :metadata do
	let(:default_palette) { 'glacier' }
	describe '#subsite_layout' do
		before { allow(controller).to receive(:subsite_config).and_return('layout' => site_layout) }
		context 'custom layout' do
			before { allow(controller).to receive(:subsite_key).and_return('custom_slug') }
			let(:site_layout) { 'custom' }
			it { expect(controller.subsite_layout).to eql('custom_slug') }
		end
		context 'default layout' do
			let(:site_layout) { 'default' }
			it { expect(controller.subsite_layout).to eql('portrait') }
		end
		context 'portable layout' do
			let(:site_layout) { 'signature' }
			it { expect(controller.subsite_layout).to eql('signature') }
		end
	end
	describe '#subsite_styles' do
		context 'custom layout' do
			let(:site_layout) { 'custom' }
			before do
				allow(controller).to receive(:subsite_config).and_return('layout' => site_layout)
				allow(controller).to receive(:subsite_key).and_return('custom_slug')
			end
			it { expect(controller.subsite_styles).to eql(['custom_slug']) }
		end
		context 'portable layouts' do
			let(:site) { FactoryBot.create(:site, layout: site_layout, palette: site_palette) }
			context "default layout and palette" do
				let(:site_layout) { 'default' }
				let(:site_palette) { 'default' }
				it { expect(controller.subsite_styles).to eql(["portrait-#{default_palette}"]) }
			end
			Dcv::Sites::Constants::PORTABLE_LAYOUTS.each do |portable_layout|
				context "#{portable_layout} layout" do
					let(:site_layout) { portable_layout }
					context "and default palette" do
						let(:site_palette) { 'default' }
						it { expect(controller.subsite_styles).to eql(["#{portable_layout}-#{default_palette}"]) }
					end
					context "and custom palette" do
						let(:site_palette) { 'custom' }
						it { expect(controller.subsite_styles).to eql(["#{portable_layout}-custom"]) }
					end
				end
			end
		end
	end
end
