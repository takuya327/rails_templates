gem 'pg'
gem 'r_decorator'
gem 'jquery-rails'
gem 'settingslogic'

gem_group :development, :test, :jenkins do 
  gem 'rspec-rails'
  gem 'debugger'
  gem 'selenium-webdriver'
  gem 'headless'
  gem 'database_cleaner'
  gem 'capybara'

  gem 'factory_girl_rails'
  gem 'faker'
end

gem_group :test do
  gem 'spork'

  #guardを使って自動テストを実施する場合
  gem 'rb-fsevent'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'guard-rake'
end

environment 'config.autoload_paths += %W(#{config.root}/lib)'
environment "config.time_zone = 'Tokyo'"
environment "config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]"
environment "config.i18n.default_locale = :ja"
environment "config.assets.initialize_on_precompile = false"

remove_file "public/index.html"
remove_file "app/assets/images/rails.png"

file 'app/models/setting.rb', <<-CODE
class Setting < Settingslogic
  source File.join( Rails.root, "config", "settings.yml" )
  namespace Rails.env
end
CODE

file 'app/decorators/application_decorator.rb', <<-CODE
class ApplicationDecorator < RDecorator::Base
  include ApplicationHelper
  
  def created_at( options={} )
    locale_datetime origin.created_at, options
  end
  
  def updated_at( options={} )
    locale_datetime origin.updated_at, options
  end
  
  protected
  
  def locale_datetime( v, options = {} )
    format = options[:format] || :default
    I18n.l( v, :format => format )
  end
  
  def string_with_linefeed( str )
    ERB::Util.html_escape( str ).gsub( "\n", "<br />" ).html_safe
  end
  
  def method_missing(method, *arg, &block)
    if origin.attribute_names.include?(method.to_s)
      attribute_with_format( method )
    else
      super
    end
  end
  
  def translate_constant_value( mod )
    n = mod.name.underscore.split('/').last
    v = origin.send( n )
    k = mod.constants.find do |key|
      mod.const_get(key) == v
    end
    k = k.downcase
    
    defaults = origin.class.lookup_ancestors.map do |klass|
      :"#{klass.model_name.i18n_key}.#{n}.#{k}"
    end
    defaults << :"#{origin.class.model_name.i18n_key}.#{n}.#{k}"
    defaults << k
    
    key = defaults.shift
    t = I18n.t( key, :default => defaults )
  end

  def value_with_format( value, key, options = {} )
    
    if origin.class.respond_to?(:i18n_scope)
      defaults = origin.class.lookup_ancestors.map do |klass|
         :"#{origin.class.i18n_scope}.format.models.#{klass.model_name.i18n_key}.#{key}"
      end
    else
      defaults = []
    end
    
    defaults << :"activerecord.format.models.#{origin.class.model_name.i18n_key}.#{key}"
    defaults << :"activerecord.format.#{key}"
    defaults << value.to_s
    #Rails.logger.debug "defaults: #{defaults}"
    
    k = defaults.shift

    options = {
      :default => defaults,
      :value => value
    }.merge( options )
    I18n.t( k, options )
  end
  
  def attribute_with_format( attribute, options = {} )
    value = (options[:value] ||= origin.send( attribute ))
    
    options = {
      :model => origin.class.model_name.human,
      :attribute => origin.class.human_attribute_name(attribute)
    }.merge( options )
    
    value_with_format( value, attribute, options )
  end
  
end
CODE

file 'config/database.yml', <<-CODE
development:
  adapter: postgresql
  encoding: utf8
  database: #{app_name}_development
  pool: 5
  username: #{app_name}
  password: #{app_name}

test:
  adapter: postgresql
  encoding: utf8
  database: #{app_name}_test
  pool: 5
  username: #{app_name}
  password: #{app_name}

jenkins:
  adapter: postgresql
  encoding: utf8
  database: #{app_name}_jenkins
  pool: 5
  username: #{app_name}
  password: #{app_name}
  
production:
  adapter: postgresql
  encoding: utf8
  database: #{app_name}_production
  pool: 5
  username: #{app_name}
  password: #{app_name}
CODE

run 'wget -o ./config/locales/ja.yml https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml'
git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }
