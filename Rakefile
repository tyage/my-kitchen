require 'pathname'
require 'shellwords'
require 'bundler/setup'
require 'highline/import'

def itamae_command(hostname, remote_user, dryrun: true, host_addr: nil, port: nil)
  %w[itamae ssh].tap do |cmd|
    cmd.push('--dry-run') if dryrun
    cmd.push('-u', remote_user) if remote_user
    cmd.push('-h', host_addr.nil? ? hostname : host_addr)
    cmd.push('-p', port) if port
    cmd.push('itamae/site.rb', "itamae/hosts/#{hostname}/default.rb")
  end
end

Pathname.glob('itamae/hosts/*').select(&:directory?).each do |hostdir|
  hostname = hostdir.basename

  desc "Cook on #{hostname}"
  namespace :apply do
    task hostname => "dryrun:#{hostname}" do
      fail 'Aborted.' unless agree('Are you sure to proceed?')

      sh itamae_command(hostname, ENV['REMOTE_USER'],
        dryrun: false, host_addr: ENV['HOST_ADDR'], port: ENV['PORT']).shelljoin
    end
  end

  desc "Dry-run on #{hostname}"
  namespace :dryrun do
    task hostname do
      sh itamae_command(hostname, ENV['REMOTE_USER'],
        dryrun: true, host_addr: ENV['HOST_ADDR'], port: ENV['PORT']).shelljoin
    end
  end
end

def local_itamae_command(hostname, dryrun: true)
  %w[itamae local].tap do |cmd|
    cmd.push('--dry-run') if dryrun
    cmd.push('itamae/site.rb', "itamae/hosts/#{hostname}/default.rb")
  end
end

desc "Cook on local"
task :local => "local:dryrun" do
  fail 'Aborted.' unless agree('Are you sure to proceed?')
  Rake::Task["local:exec"].invoke
end

desc "Cook on local without dry-run"
namespace :local do
  task :exec do
    sh local_itamae_command(ENV['LOCAL_HOST'], dryrun: false).shelljoin
  end
end

desc "Dry-run on local"
namespace :local do
  task :dryrun do
    sh local_itamae_command(ENV['LOCAL_HOST'], dryrun: true).shelljoin
  end
end
