module Staypuft
  module Concerns
    module HostDetailsHelper
      extend ActiveSupport::Concern

      # Returns memory in GB
      def mem
        mem_arr = self.facts_hash["memorytotal"]
        if mem_arr
          mem_str, mem_unit = mem_arr.split(" ")
          mem_number = mem_str.to_f
          case mem_unit
          when "MB"
            mem_number / 1024
          when "GB"
            mem_number
          when "TB"
            mem_number * 1024
          else
            nil
          end
        else
          nil
        end
      end

      # Returns total number of processes
      def cpus
        self.facts_hash["processorcount"]
      end

      # Returns model
      def model_type
        self.facts_hash["hardwaremodel"]
      end

      # Returns array of NIC names
      def network_interfaces
        if self.facts_hash["interfaces"]
          self.facts_hash["interfaces"].split(",")
        else
          nil
        end
      end

      # Returns architecture
      def architectures
        if self.facts_hash["architecture"]
          self.facts_hash["architecture"].name
        else
          nil
        end
      end

      # Returns array of block device names
      def blockdevices
        if self.facts_hash["blockdevices"]
          self.facts_hash["blockdevices"].split(",")
        else
          nil
        end
      end
    end
  end
end
