#! /usr/bin/env ruby
#
# check-termination-protection
#
# DESCRIPTION:
#   This plugin retrieves the value of the cpu balance for all servers
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: aws-sdk
#   gem: sensu-plugin
#
# USAGE:
#   ./check-termination-protection.rb -a <access-key> -k <secret-key> -r us-east-1
#
# NOTES:
#
# LICENSE:
#   Fadel Wanssa
#   Solace Corporation
#

require 'sensu-plugins-aws'
require 'sensu-plugin/check/cli'
require 'aws-sdk'

class TerminationProtection < Sensu::Plugin::Check::CLI

  option :aws_access_key,
         short: '-a AWS_ACCESS_KEY',
         long: '--aws-access-key AWS_ACCESS_KEY',
         description: "AWS Access Key. Either set ENV['AWS_ACCESS_KEY'] or provide it as an option",
         default: ENV['AWS_ACCESS_KEY']

  option :aws_secret_access_key,
         short: '-k AWS_SECRET_KEY',
         long: '--aws-secret-access-key AWS_SECRET_KEY',
         description: "AWS Secret Access Key. Either set ENV['AWS_SECRET_KEY'] or provide it as an option",
         default: ENV['AWS_SECRET_KEY']

  option :aws_region,
         short: '-r AWS_REGION',
         long: '--aws-region REGION',
         description: 'AWS Region (such as us-east-1).',
         default: 'us-east-1'

  def aws_config
    { access_key_id: config[:aws_access_key],
      secret_access_key: config[:aws_secret_access_key],
      region: config[:aws_region] }
  end

  def run
    ec2 = Aws::EC2::Client.new aws_config
    instances = ec2.describe_instances()

    messages = "\n"
    level = 0
    instances.reservations.each do |reservation|
      reservation.instances.each do |instance|
        resp = ec2.describe_instance_attribute({
                                                   attribute: "disableApiTermination",
                                                   instance_id: "#{instance.instance_id}",
                                               }).to_h
        id = resp[:instance_id]
        termination_protection = resp[:disable_api_termination][:value]
        if not termination_protection
          messages  << "Termination protection for instance id: #{id} is: #{termination_protection}\n"
          level = 2
        end
      end
    end
    ok messages if level == 0
    warning messages if level == 1
    critical messages if level == 2
  end
end
