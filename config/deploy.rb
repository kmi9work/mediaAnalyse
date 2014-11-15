require 'rvm/capistrano' # Для работы rvm
require 'bundler/capistrano' # Для работы bundler. При изменении гемов bundler автоматически обновит все гемы на сервере, чтобы они в точности соответствовали гемам разработчика.

set :application, "msystem"
set :rails_env, "production"
set :domain, "michael@31.24.30.28" # Это необходимо для деплоя через ssh. Именно ради этого я настоятельно советовал сразу же залить на сервер свой ключ, чтобы не вводить паролей.
set :deploy_to, "/srv/#{application}"
set :use_sudo, false
set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"
set :msystem_pid, "#{deploy_to}/shared/log/msystem.rb.pid"

set :rvm_ruby_string, :local # Это указание на то, какой Ruby интерпретатор мы будем использовать.

set :scm, :git # Используем git. Можно, конечно, использовать что-нибудь другое - svn, например, но общая рекомендация для всех кто не использует git - используйте git.
set :repository,  "git@github.com:kmi9work/mediaAnalyse.git" # Путь до вашего репозитария. Кстати, забор кода с него происходит уже не от вас, а от сервера, поэтому стоит создать пару rsa ключей на сервере и добавить их в deployment keys в настройках репозитария.
set :branch, "msystem" # Ветка из которой будем тянуть код для деплоя.
set :deploy_via, :remote_cache # Указание на то, что стоит хранить кеш репозитария локально и с каждым деплоем лишь подтягивать произведенные изменения. Очень актуально для больших и тяжелых репозитариев.

role :web, domain
role :app, domain
role :db,  domain, :primary => true

before 'deploy:setup', 'rvm:install_rvm', 'rvm:install_ruby' # интеграция rvm с capistrano настолько хороша, что при выполнении cap deploy:setup установит себя и указанный в rvm_ruby_string руби.

after 'deploy:update_code', :roles => :app do
  # Здесь для примера вставлен только один конфиг с приватными данными - database.yml. Обычно для таких вещей создают папку /srv/myapp/shared/config и кладут файлы туда. При каждом деплое создаются ссылки на них в нужные места приложения.
  puts "ololo"
  run "rm -f #{current_release}/config/database.yml"
  run "ln -s #{deploy_to}/shared/config/database.yml #{current_release}/config/database.yml"

  run "chmod +x #{current_release}/lib/daemons/msystem_ctl"
end

# Далее идут правила для перезапуска unicorn. Их стоит просто принять на веру - они работают.
# В случае с Rails 3 приложениями стоит заменять bundle exec unicorn_rails на bundle exec unicorn
namespace :deploy do
  task :restart do
    run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D; fi"
  end
  task :start do
    run "bundle exec unicorn -c #{unicorn_conf} -E #{rails_env} -D"
  end
  task :stop do
    run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
  end
end

namespace :msystem do
  task :restart do
    run "if [ -f #{msystem_pid} ] && [ -e /proc/$(cat #{msystem_pid}) ]; then kill -9 `cat #{msystem_pid}`; fi"
    run "cd #{deploy_to}/current && bundle exec rake daemon:msystem:start"
  end
end


# # config valid only for Capistrano 3.1
# lock '3.2.1'

# set :application, 'my_app_name'
# set :repo_url, 'git@example.com:me/my_repo.git'

# # Default branch is :master
# # ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# # Default deploy_to directory is /var/www/my_app
# # set :deploy_to, '/var/www/my_app'

# # Default value for :scm is :git
# # set :scm, :git

# # Default value for :format is :pretty
# # set :format, :pretty

# # Default value for :log_level is :debug
# # set :log_level, :debug

# # Default value for :pty is false
# # set :pty, true

# # Default value for :linked_files is []
# # set :linked_files, %w{config/database.yml}

# # Default value for linked_dirs is []
# # set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# # Default value for default_env is {}
# # set :default_env, { path: "/opt/ruby/bin:$PATH" }

# # Default value for keep_releases is 5
# # set :keep_releases, 5

# namespace :deploy do

#   desc 'Restart application'
#   task :restart do
#     on roles(:app), in: :sequence, wait: 5 do
#       # Your restart mechanism here, for example:
#       # execute :touch, release_path.join('tmp/restart.txt')
#     end
#   end

#   after :publishing, :restart

#   after :restart, :clear_cache do
#     on roles(:web), in: :groups, limit: 3, wait: 10 do
#       # Here we can do anything such as:
#       # within release_path do
#       #   execute :rake, 'cache:clear'
#       # end
#     end
#   end

# end
