require 'tmpdir'
require 'rails_helper'

describe Dcv::Sites::Export::Directory do
	let(:export) { described_class.new(site.slug, Dir.mktmpdir) }
	let(:export_dir) { export.run }
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site) { import.run }
	after do
		FileUtils.remove_entry export_dir
	end
	describe '#run' do
		it 'exports equivalent site properties' do
			export_properties = File.join(export_dir, 'properties.yml')
			import_properties = File.join(source, 'properties.yml')
			expected = YAML.load(File.read(import_properties))
			expected.compact!
			FileUtils.cp(export_properties, 'tmp')
			actual = YAML.load(File.read(export_properties))
			actual.compact!
			expect(actual).to eql(expected)
		end
		skip 'exports links' do
		end
		skip 'exports pages' do
		end
		skip 'exports images' do
		end
	end
end
