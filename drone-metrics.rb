#!/usr/bin/env ruby
#

require 'aws-sdk-cloudwatch'

class Report
  attr_reader :client, :plugin, :drone

  def initialize
    aws_region = Plugin.new.aws_region || 'eu-west-1'
    @client = Aws::CloudWatch::Client.new(region: aws_region)
    @plugin = Plugin.new
    @drone = Drone.new
  end

  def time_taken
    drone.finished.to_i - drone.created.to_i
  end

  def namespace
    plugin.namespace || 'Drone'
  end

  def metric_data
    {
      metric_name: 'BuildTime',
      timestamp: Time.now,
      value: time_taken,
      unit: 'Seconds',
      storage_resolution: 60,
      dimensions: [
        {
          name: 'Repo',
          value: drone.repo_name
        }
      ]
    }
  end

  def add_metric
    client.put_metric_data(
      namespace: namespace,
      metric_data: [metric_data]
    )

    puts metric_data
  end
end

class Drone
  # These are environment variables set by Drone itself
  def drone_env(name)
    ENV.fetch("DRONE_#{name.upcase}", nil)
  end

  def author
    drone_env('commit_author')
  end

  def author_email
    drone_env('commit_author_email')
  end

  def branch
    drone_env('commit_branch')
  end

  def build
    drone_env('build_number')
  end

  def status
    drone_env('job_status')
  end

  def created
    drone_env('build_created')
  end

  def started
    drone_env('build_started')
  end

  def finished
    drone_env('build_finished')
  end

  def link
    drone_env('build_link')
  end

  def repo_name
    drone_env('repo')
  end

  def repo_owner
    drone_env('repo_owner')
  end

  def sha
    drone_env('commit_sha')
  end

  def commit_message
    drone_env('commit_message')
  end

  def commit_link
    drone_env('commit_link')
  end

  def prev_build_status
    drone_env('prev_build_status')
  end
end

class Plugin
  # Any custom parameters
  def set_parameter(parameter_name, required = true)
    parameter = 'PLUGIN_' + parameter_name.upcase

    abort("Must set #{parameter}") if required && ENV[parameter].nil?

    return false if ENV[parameter].nil?

    ENV[parameter]
  end

  def namespace
    set_parameter('namespace', false)
  end

  def aws_region
    set_parameter('aws_region', false)
  end
end

Report.new.add_metric
