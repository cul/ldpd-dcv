require 'tmpdir'
require 'rails_helper'

describe Dcv::Sites::Export::Directory do
	let(:export) { described_class.new(site.slug, Dir.mktmpdir) }
	let(:export_dir) { export.run }
	let(:export_properties) { File.join(export_dir, 'properties.yml') }
	let(:source) { fixture("sites/import/directory").path }
	let(:import) { Dcv::Sites::Import::Directory.new(source) }
	let(:site) { import.run }
	after do
		FileUtils.remove_entry export_dir
	end
	describe '#run' do
		before do
			FileUtils.cp(export_properties, 'tmp')
		end
		it 'exports equivalent site properties' do
			import_properties = File.join(source, 'properties.yml')
			expected = YAML.load(File.read(import_properties)).except('nav_links', 'search_configuration', 'permissions').compact
			actual = YAML.load(File.read(export_properties)).except('nav_links', 'search_configuration', 'permissions').compact
			expect(actual).to eql(expected)
		end
		it 'exports links' do
			import_properties = File.join(source, 'properties.yml')
			expected = YAML.load(File.read(import_properties)).fetch('nav_links', :no_key_from_expected)
			actual = YAML.load(File.read(export_properties)).fetch('nav_links', :no_key_from_actual)
			expect(actual).to eql(expected)
		end
		it 'exports search_configuration' do
			import_properties = File.join(source, 'properties.yml')
			expected = YAML.load(File.read(import_properties)).fetch('search_configuration', :no_key_from_expected)
			actual = YAML.load(File.read(export_properties)).fetch('search_configuration', :no_key_from_actual)
			expect(actual).to eql(expected)
		end
		it 'exports permissions' do
			expect(site.permissions.remote_ids).to be_present
			import_properties = File.join(source, 'properties.yml')
			expected = YAML.load(File.read(import_properties)).fetch('permissions', :no_key_from_expected)
			actual = YAML.load(File.read(export_properties)).fetch('permissions', :no_key_from_actual)
			puts File.read(export_properties)
			expect(actual).to eql(expected)
		end
		skip 'exports pages' do
		end
		skip 'exports images' do
		end
	end
end
