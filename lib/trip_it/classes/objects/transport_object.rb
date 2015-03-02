module TripIt
  class TransportObject < ReservationObject
    traveler_array_param :traveler
    
    def initialize(client, obj_id = nil, source = nil)
      @client = client
      unless obj_id.nil?
        @obj_id = obj_id
        populate(source)
      end
    end
    
    def populate(source)
      info = source || @client.get("/transport", :id => @obj_id)["TransportObject"]
      super(info)
      @segment   = TripIt::TransportSegment.new 
      @traveler  = TripIt::Traveler.new 
      chkAndPopulate(@segment, TripIt::TransportSegment, info["Segment"])
      chkAndPopulate(@traveler, TripIt::Traveler, info["Traveler"])
    end
    
    def sequence
      arr = super
      arr + ["@segment", "@traveler"]
    end
  end
end
