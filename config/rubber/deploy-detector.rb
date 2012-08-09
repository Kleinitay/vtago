# config/rubber/deploy-delayed_job.rb

namespace :rubber do
  namespace :detector do

    after "fix_and_compile:fix", "rubber:detector:restart"

    desc "Stop the delayed_job process"
    task :stop, :roles => :detector do
      run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 1 --queues=detect stop"
    end

    desc "Start the delayed_job process"
    task :start, :roles => :detector do
      run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 1 --queues=detect start"
    end

    desc "Restart the delayed_job process"
    task :restart, :roles => :detector do
      run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job -n 1 --queues=detect restart"
    end


  end
end
