require_relative 'nvst'

Eye::Nvst.process 'unicorn' do
  pid_file 'tmp/pids/unicorn.pid'
  stdall 'log/unicorn.log'
  start_command 'bin/nvst bundle exec unicorn -Dc config/unicorn.rb -E production'
  stop_command 'kill -QUIT {PID}'

  # stop signals:
  # http://unicorn.bogomips.org/SIGNALS.html
  stop_signals [:TERM, 10.seconds]

  # soft restart
  restart_command 'kill -USR2 {PID}'

  check :cpu, every: 30.seconds, below: 20, times: 3
  check :memory, every: 30.seconds, below: 200.megabytes, times: [3, 5]

  start_timeout 100.seconds
  restart_grace 30.seconds

  monitor_children do
    stop_command 'kill -QUIT {PID}'
    check :cpu, every: 30.seconds, below: 80, times: 3
    check :memory, every: 30.seconds, below: 200.megabytes, times: [3, 5]
  end
end
