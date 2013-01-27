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

TEMPLATE_REPO_PATH = 'https://raw.github.com/takuya327/rails_templates/master'
def template_to_local( path )
  run "wget -O #{path} #{TEMPLATE_REPO_PATH}/#{path}"
end

template_to_local 'app/decorators/application_decorator.rb'
template_to_local 'config/initializers/original_customize.rb'
template_to_local 'config/settings.yml'
template_to_local 'Guardfile'
run 'wget -O config/locales/ja.yml https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml'

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

run "rvm gemset create #{app_name}"
file ".rvmrc", "rvm use 1.9.3@#{app_name}"
run "rvm rvmrc trust ."

run 'bundle install'
rake 'rspec:install'

git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }
