Rails.autoloaders.each do |autoloader|
  # ignore monkey patches
  autoloader.ignore Rails.root.join('lib/dcv/rails/routing_patches.rb')
  autoloader.ignore Rails.root.join('lib/dcv/solr/document_adapter/mods_xml/solrizer_patch.rb')
  # inflections for some all-caps module names
  autoloader.inflector.inflect(
    'fcrepo3' => 'FCREPO3',
    'nfo' => 'NFO',
    'nie' => 'NIE',
    'olo' => 'OLO',
    'ore' => 'ORE',
    'pcdm' => 'PCDM',
    'pimo' => 'PIMO',
    'rdf' => 'RDF',
    'sc' => 'SC'
  )
end