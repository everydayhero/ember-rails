require 'rails'
require 'ember/rails/version'
require 'ember/rails/engine'
require 'ember/source'
require 'ember/data/source'
require 'handlebars/source'

module Ember
  module Rails
    class Railtie < ::Rails::Railtie
      config.ember = ActiveSupport::OrderedOptions.new
      config.ember.bundle_source = true

      generators do |app|
        app ||= ::Rails.application # Rails 3.0.x does not yield `app`

        app.config.generators.assets = false

        ::Rails::Generators.configure!(app.config.generators)
        ::Rails::Generators.hidden_namespaces.uniq!
        require "generators/ember/resource_override"
      end

      initializer "ember_rails.setup_vendor", :after => "ember_rails.setup", :group => :all do |app|
        variant = app.config.ember.variant || (::Rails.env.production? ? :production : :development)
        ext = variant == :production ? ".prod.js" : ".js"

        ember_source_path = ::Ember::Source.bundled_path_for("ember#{ext}")
        ember_data_source_path = ::Ember::Data::Source.bundled_path_for("ember-data#{ext}")

        if app.config.ember.bundle_source
          # Copy over the desired ember, ember-data, and handlebars bundled in
          # ember-source, ember-data-source, and handlebars-source to a tmp folder.
          tmp_path = app.root.join("tmp/ember-rails")
          FileUtils.cp(ember_source_path, tmp_path.join("ember.js"))
          FileUtils.cp(ember_data_source_path, tmp_path.join("ember-data.js"))
          app.assets.append_path(tmp_path)
        else
          app.assets.append_path(File.dirname(ember_data_source_path))
          app.assets.append_path(File.dirname(ember_source_path))
        end

        # Make the handlebars.js and handlebars.runtime.js bundled
        # in handlebars-source available.
        app.assets.append_path(File.expand_path('../', ::Handlebars::Source.bundled_path))

        # Allow a local variant override
        ember_path = app.root.join("vendor/assets/ember/#{variant}")
        app.assets.prepend_path(ember_path.to_s) if ember_path.exist?
      end

      initializer "ember_rails.es5_default", :group => :all do |app|
        if defined?(Closure::Compiler) && app.config.assets.js_compressor == :closure
          Closure::Compiler::DEFAULT_OPTIONS[:language_in] = 'ECMASCRIPT5'
        end
      end
    end
  end
end
