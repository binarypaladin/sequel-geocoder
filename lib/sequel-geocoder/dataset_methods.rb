# -*- coding: utf-8 -*-
require 'sequel-geocoder/sql'

module Sequel::Plugins::Geocoder
  module DatasetMethods
    attr_accessor :geocoder_options

    # See Geocoder::Store::ActiveRecord.included generated scope.
    def geocoded
      where(
        Sequel.~(geocoder_options[:latitude] => nil),
        Sequel.~(geocoder_options[:longitude] => nil)
      )
    end

    # See Geocoder::Store::ActiveRecord.included generated scope.
    def not_geocoded
      where(geocoder_options[:latitude] => nil)
      .or(geocoder_options[:longitude] => nil)
    end

    # See Geocoder::Store::ActiveRecord.included generated scope.
    def near(location, *args)
      latitude, longitude = ::Geocoder::Calculations.extract_coordinates(location)

      if ::Geocoder::Calculations.coordinates_present?(latitude, longitude)
        geocoder_near_ds(latitude, longitude, *args)
      else
        geocoder_select_ds(nil, nil, nil).where(false)
      end
    end

    # See Geocoder::Store::ActiveRecord.included generated scope.
    def within_bounding_box(bounds)
      sw_lat, sw_lng, ne_lat, ne_lng = bounds.flatten if bounds
      if sw_lat && sw_lng && ne_lat && ne_lng
        where(
          Geocoder::Sql.within_bounding_box(sw_lat, sw_lng, ne_lat, ne_lng),
          geocoder_options[:latitude],
          geocoder_options[:longitude]
        )
      else
        geocoder_select_ds(nil, nil, nil).where(false)
      end
    end

    def distance_from_sql(location, *args)
      latitude, longitude = Geocoder::Calculations.extract_coordinates(location)
      if Geocoder::Calculations.coordinates_present?(latitude, longitude)
        geocoder_distance_sql(latitude, longitude, *args)
      end
    end

    private # ----------------------------------------------------------------

    # Gets a base dataset get records within a radius (in kilometers) of the
    # given point. In most cases it operates just like
    # Geocoder::Store::ActiveRecord::ClassMethods#near_scope_options except that
    # the +:select+ and +:order+ options take an array of objects suitable to
    # use in a Sequel::Dataset.
    def geocoder_near_ds(latitude, longitude, radius = 20, options = {})
      options[:units] ||= (geocoder_options[:units] || Geocoder.config.units)
      options[:units] = options[:units].to_sym if options[:units]
      options[:exclude] = options[:exclude].pk if options[:exclude].respond_to?(:pk)

      select_distance = options.fetch(:select_distance, true)
      select_bearing = options.fetch(:select_bearing, true)
      distance = select_distance ? geocoder_distance_sql(latitude, longitude, options) : nil
      bearing = select_bearing ? geocoder_bearing_sql(latitude, longitude, options) : nil
      distance_column = options.fetch(:distance_column, :distance)
      bearing_column = options.fetch(:bearing_column, :bearing)

      ds = geocoder_select_ds(
        options[:select],
        select_distance ? distance : nil,
        select_bearing ? bearing : nil,
        distance_column,
        bearing_column,
      )

      ds = ds.where(
        Sql.within_bounding_box(
          *Geocoder::Calculations.bounding_box([latitude, longitude], radius, options)
        ),
        latitude: geocoder_options[:latitude],
        longitude: geocoder_options[:longitude]
      )

      # TODO: It seems like there is a better way of handling this without using
      # the same equation twice. Perhaps a subselect or something similar?
      #
      # Or some reading indicates that SQL is pretty smart about this sort of
      # thing.
      unless using_sqlite?
        min_radius = options.fetch(:min_radius, 0).to_f
        ds = ds.where("? BETWEEN ? AND ?", distance, min_radius, radius)
      end

      # Does the work of
      # Geocoder::Store::ActiveRecord::ClassMethods#add_exclude_condition
      ds = ds.where(Sequel.~(ds.model.primary_key => options[:exclude])) if
        options[:exclude]

      if options.include?(:order) && options[:order]
        ds = ds.order(options[:order])
      elsif select_distance
        ds = ds.order(Sequel.asc(distance_column))
      end

      ds
    end

    # See Geocoder::Store::ActiveRecord::ClassMethods#distance_sql
    def geocoder_distance_sql(latitude, longitude, options = {})
      geocoder_placeholder_literal('distance', latitude, longitude, options)
    end

    # See Geocoder::Store::ActiveRecord::ClassMethods#bearing_sql
    def geocoder_bearing_sql(latitude, longitude, options = {})
      geocoder_placeholder_literal('bearing', latitude, longitude, options)
    end

    # Creates a Sequel::SQL::PlaceholderLiteralString for the equations using
    # the SQL provided by ::Geocoder::Sql and inserts the configured columns
    # in it. It also wraps it in parens. The resulting Sequel dataset can then
    # be qualified if it needs to be.
    def geocoder_placeholder_literal(method_postfix, latitude, longitude, options = {})
      return unless ::Geocoder::Calculations.coordinates_present?(latitude, longitude)
      Sequel::SQL::PlaceholderLiteralString.new(
        Sql.__send__(
          :"#{geocoder_method_prefix}_#{method_postfix}",
          latitude, longitude, options
        ), {
          latitude: geocoder_options[:latitude],
          longitude: geocoder_options[:longitude]
        }, { parens: true }
      )
    end

    # See Geocoder::Store::ActiveRecord::ClassMethods#select_clause. This
    # returns a dataset with the appropriate select parameters set.
    def geocoder_select_ds(columns, distance = false, bearing = false, distance_column = :distance, bearing_column = :bearing)
      return select(self.primary_key) if columns == :id_only

      selects = columns.respond_to?(:map) ? columns.map(&:to_sym) : model.columns.dup
      selects << Sequel.as(distance, distance_column) if distance != false
      selects << Sequel.as(bearing, bearing_column) if bearing != false
      select(*selects)
    end

    # Exists just to DRY things up a bit.
    def geocoder_method_prefix
      using_sqlite? ? "approx" : "full"
    end

    def using_sqlite?
      db.opts[:adapter].match(/sqlite/i)
    end
  end
end
