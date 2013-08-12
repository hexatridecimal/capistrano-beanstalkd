require "capistrano"
require "capistrano/version"

module CapistranoBeanstalkd
  class CapistranoIntegration
    def self.load_into(capistrano_config)
      capistrano_config.load do

        _cset(:workers, {"*" => 1})
        _cset(:beanstalkd_kill_signal, "QUIT")
        _cset(:interval, "5")

        def workers_roles
          return workers.keys if workers.first[1].is_a? Hash
          [:beanstalkd_worker]
        end

        def for_each_workers(&block)
          if workers.first[1].is_a? Hash
            workers_roles.each do |role|
              yield(role.to_sym, workers[role.to_sym])
            end
          else
            yield(:beanstalkd_worker,workers)
          end
        end

        def status_command
          "if [ -e #{current_path}/tmp/pids/beanstalkd_work_1.pid ]; then \
            for f in $(ls #{current_path}/tmp/pids/beanstalkd_work*.pid); \
              do ps -p $(cat $f) | sed -n 2p ; done \
           ;fi"
        end

        def start_command(queue, pid)
          "cd #{current_path} && RAILS_ENV=#{rails_env} QUEUES=\"#{queue}\" \
           #{fetch(:bundle_cmd, "bundle")} exec rake backburner:work"
        end

        def stop_command
          "if [ -e #{current_path}/tmp/pids/beanstalkd_work_1.pid ]; then \
           for f in `ls #{current_path}/tmp/pids/beanstalkd_work*.pid`; \
             do #{try_sudo} kill -s #{beanstalkd_kill_signal} `cat $f` \
             && rm $f ;done \
           ;fi"
        end

        namespace :beanstalkd do
          desc "See current worker status"
          task :status, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            run(status_command)
          end

          desc "Start Beanstalkd workers"
          task :start, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            for_each_workers do |role, workers|
              worker_id = 1
              workers.each_pair do |queue, number_of_workers|
                logger.info "Starting #{number_of_workers} worker(s) with QUEUE: #{queue}"
                threads = []
                number_of_workers.times do
                  pid = "./tmp/pids/beanstalkd_work_#{worker_id}.pid"
                  threads << Thread.new(pid) { |pid| run(start_command(queue, pid), :roles => role) }
                  worker_id += 1
                end
                threads.each(&:join)
              end
            end
          end

          desc "Quit running Beanstalkd workers"
          task :stop, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            run(stop_command)
          end

          desc "Restart running Beanstalkd workers"
          task :restart, :roles => lambda { workers_roles() }, :on_no_matching_servers => :continue do
            stop
            start
          end

        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  CapistranoBeanstalkd::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
end
