include_recipe "rabbitmq"
include_recipe "supervisor"

if node['twoscoops']['application_revision'] == nil
  celery_path = "#{node['twoscoops']['application_path']}/#{node['twoscoops']['project_name']}"
else
  celery_path = "#{node['twoscoops']['application_path']}/#{node['twoscoops']['application_name']}/current/#{node['twoscoops']['project_name']}"
end

celery_env = {
  "PYTHON_PATH" => "#{celery_path}" 
}

user "celery"

directory "/var/run/celery" do
  owner "celery"
end

directory "/var/lib/celery" do
  owner "celery"
end

directory "#{node['twoscoops']['application_path']}/logs/celery" do
  owner "celery"
  recursive true
end

celeryd_command = "celeryd --app=#{node['twoscoops']['project_name']} "
celeryd_options = {
  "broker" => node["twoscoops"]["celery"]["broker"],
  "concurrency" => node["twoscoops"]["celery"]["concurrency"],
  "queues" => "celery",
  "loglevel" => "INFO"
}.each do |k,v|
  celeryd_command = celeryd_command + "--#{k}=#{v} "
end

supervisor_service "celeryd" do
  command celeryd_command
  user "celery"
  autostart true
  directory celery_path
  environment celery_env
  stdout_logfile "#{node['twoscoops']['application_path']}/logs/celery/worker.log"
  stderr_logfile "#{node['twoscoops']['application_path']}/logs/celery/worker.log"
  action :enable
end

celery_beat_command = "celerybeat "
celery_beat_options = {
  "broker" => node["twoscoops"]["celery"]["broker"],
  "pidfile" => "/var/run/celery/celery-beat.pid",
  "schedule" => "/var/lib/celery/celerybeat-schedule",
  "loglevel" => "INFO"
}.each do |k,v|
  celery_beat_command = celery_beat_command + "--#{k}=#{v} "
end

supervisor_service "celery-beat" do
  command celery_beat_command
  user "celery"
  autostart true
  directory celery_path
  environment celery_env
  stdout_logfile "#{node['twoscoops']['application_path']}/logs/celery/beat.log"
  stderr_logfile "#{node['twoscoops']['application_path']}/logs/celery/beat.log"
  action :enable
end
