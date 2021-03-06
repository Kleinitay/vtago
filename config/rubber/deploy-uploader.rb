# config/rubber/deploy-delayed_job.rb

namespace :rubber do
  namespace :uploader do

    after "fix_and_compile:fix", "rubber:uploader:restart"

    desc "Stop the delayed_job process"
    task :stop, :roles => :uploader do
      run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 5 --queues=upload stop"
    end

    desc "Start the delayed_job process"
    task :start, :roles => :uploader do
      run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 5 --queues=upload start"
    end

    desc "Restart the delayed_job process"
    task :restart, :roles => :uploader do
      run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 5 --queues=upload restart"
    end

  end
end
