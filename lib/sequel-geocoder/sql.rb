# -*- coding: utf-8 -*-
require 'geocoder/sql'

module Sequel::Plugins::Geocoder
  module Sql
    extend ::Geocoder::Sql

    # Creates strings that can be used in a Sequel query with placeholders.
    # The placeholders can have the column names properly qualified where
    # necessary. This allows the existing SQL from Geocoder to be used
    # without any modifications.
    #
    # See ::Geocoder::Sql for explanations on what the methods actually do.
    class << self
      [
        :full_distance,
        :approx_distance,
        :full_bearing,
        :approx_bearing
      ].each do |m|
        define_method(m) do |latitude, longitude, options={}|
          super(latitude, longitude, ':latitude', ':longitude', options)
        end
      end

      def within_bounding_box(sw_lat, sw_lng, ne_lat, ne_lng)
        super(sw_lat, sw_lng, ne_lat, ne_lng, ':latitude', ':longitude')
      end
    end
  end
end
