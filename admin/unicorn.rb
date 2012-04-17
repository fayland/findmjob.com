# set path to app that will be used to configure unicorn,
# note the trailing slash in this example
@dir = "/findmjob.com/admin/"

worker_processes 2
working_directory @dir

preload_app true

timeout 30

# Specify path to socket unicorn listens to,
# we will use this in our nginx.conf later
listen "/tmp/findmjob.admin.sock", :backlog => 64

# Set process id path
pid "/tmp/unicorn.pid"

# Set log file paths
stderr_path "/findmjob.com/log/unicorn.stderr.log"
stdout_path "/findmjob.com/log/unicorn.stdout.log"