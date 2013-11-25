# -*- encoding: utf-8 -*-
#
# Author:: Fletcher Nichol (<fnichol@nichol.ca>)
#
# Copyright (C) 2013, Fletcher Nichol
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'kitchen/provisioner/chef_base'

module Kitchen

  module Provisioner

    # Chef Solo provisioner.
    #
    # @author Fletcher Nichol <fnichol@nichol.ca>
    class ChefSolo < ChefBase

      def create_sandbox
        create_chef_sandbox { prepare_solo_rb }
      end

      def run_command
        [
          sudo('chef-solo'),
          "--config #{config[:root_path]}/solo.rb",
          "--json-attributes #{config[:root_path]}/dna.json",
          config[:log_file] ? "--logfile #{config[:log_file]}" : nil,
          "--log_level #{config[:log_level]}"
        ].join(" ")
      end

      private

      def prepare_solo_rb
        solo = []
        solo << %{node_name "#{instance.name}"}
        solo << %{file_cache_path "#{config[:root_path]}/cache"}
        solo << %{cookbook_path ["#{config[:root_path]}/cookbooks","#{config[:root_path]}/site-cookbooks"]}
        solo << %{role_path "#{config[:root_path]}/roles"}
        if config[:chef]
          if config[:chef][:http_proxy]
            solo << %{http_proxy "#{config[:chef][:http_proxy]}"}
          end
          if config[:chef][:https_proxy]
            solo << %{https_proxy "#{config[:chef][:https_proxy]}"}
          end
          if config[:chef][:no_proxy]
            solo << %{no_proxy "#{config[:chef][:no_proxy]}"}
          end
        end
        if instance.suite.data_bags_path
          solo << %{data_bag_path "#{config[:root_path]}/data_bags"}
        end
        if instance.suite.environments_path
          solo << %{environment_path "#{config[:root_path]}/environments"}
        end
        if instance.suite.environment
          solo << %{environment "#{instance.suite.environment}"}
        end
        if instance.suite.encrypted_data_bag_secret_key_path
          secret = "#{config[:root_path]}/encrypted_data_bag_secret"
          solo << %{encrypted_data_bag_secret "#{secret}"}
        end

        File.open(File.join(tmpdir, "solo.rb"), "wb") do |file|
          file.write(solo.join("\n"))
        end
      end
    end
  end
end
