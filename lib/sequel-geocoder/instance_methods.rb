# -*- coding: utf-8 -*-
require 'geocoder/stores/base'

module Sequel
  module Plugins
    module Geocoder
      module InstanceMethods
        include ::Geocoder::Store::Base

        # Identical to Geocoder::Store::ActiveRecord#geocode
        def geocode
          do_lookup(false) do |o,rs|
            if r = rs.first
              unless r.latitude.nil? or r.longitude.nil?
                o.__send__  "#{self.class.geocoder_options[:latitude]}=",  r.latitude
                o.__send__  "#{self.class.geocoder_options[:longitude]}=", r.longitude
              end
              r.coordinates
            end
          end
        end

        alias_method :fetch_coordinates, :geocode

        # Identical to Geocoder::Store::ActiveRecord#reverse_geocode
        def reverse_geocode
          do_lookup(true) do |o,rs|
            if r = rs.first
              unless r.address.nil?
                o.__send__ "#{self.class.geocoder_options[:fetched_address]}=", r.address
              end
              r.address
            end
          end
        end

        alias_method :fetch_address, :reverse_geocode
      end
    end
  end
end
