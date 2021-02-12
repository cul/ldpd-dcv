class CreateScopeFilter < ActiveRecord::Migration
  def change
    create_table :scope_filters do |t|
      t.string :filter_type
      t.string :value
      t.references :scopeable, polymorphic: true
      t.timestamps
    end
    Site.all.each do |site|
      raw_att = site.instance_variable_get(:@attributes)["search_configuration"]
      search_config_hash = JSON.load(raw_att.value_before_type_cast)
      search_config_hash['scope_constraints']&.each do |type, values|
        Array(values).each {|value| site.scope_filters << ScopeFilter.new(filter_type: type, value: value)}
      end
      search_config_hash.delete('scope_constraints')
      site.search_configuration = search_config_hash
      site.save!
    end
  end
end
