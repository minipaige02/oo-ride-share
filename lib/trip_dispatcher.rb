require 'csv'
require 'time'

require_relative 'passenger'
require_relative 'trip'
require_relative 'driver'

module RideShare
  class TripDispatcher
    attr_reader :drivers, :passengers, :trips

    def initialize(directory: './support')
      @passengers = Passenger.load_all(directory: directory)
      @trips = Trip.load_all(directory: directory)
      @drivers = Driver.load_all(directory: directory)
      connect_trips
    end

    def find_passenger(id)
      Passenger.validate_id(id)
      return @passengers.find { |passenger| passenger.id == id }
    end

    def find_driver(id)
      Driver.validate_id(id)
      return @drivers.find { |driver| driver.id == id }
    end
    
    def inspect
      # Make puts output more useful
      return "#<#{self.class.name}:0x#{object_id.to_s(16)} \
              #{trips.count} trips, \
              #{drivers.count} drivers, \
              #{passengers.count} passengers>"
    end

    def find_next_trip_id
      @trips.map(&:id).max.succ
    end

    def find_available_driver
      driver = @drivers.find { |driver| driver.status == :AVAILABLE }
      raise RuntimeError, "No available drivers" unless driver
      return driver
    end

    def request_trip(passenger_id)
      driver = find_available_driver
      passenger = find_passenger(passenger_id)

      trip = Trip.new(id: find_next_trip_id, passenger: passenger, passenger_id: passenger_id,
                      start_time: Time.now, end_time: nil, rating: nil,
                      driver: driver)

      driver.dispatch(trip)
      passenger.add_trip(trip)
      @trips << trip

      return trip
    end

    private

    def connect_trips
      @trips.each do |trip|
        passenger = find_passenger(trip.passenger_id)
        driver = find_driver(trip.driver_id)
        
        trip.connect(passenger, driver)
      end

      return trips
    end
  end
end
