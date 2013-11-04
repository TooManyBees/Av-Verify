require_relative "avconstants"

module CorrelateSections

  def correlate_all
    correlate_doors(self.rooms)
    correlate_resets(self.resets, self.mobiles, self.objects, self.rooms)
    correlate_shops(self.shops, self.mobiles)
    correlate_specials(self.specials, self.mobiles)
  end

  def correlate_doors(rooms)
    return if rooms.nil?
    rooms.each do |room|
      room.doors.each_value do |door|
        next if door[:dest].between?(-1, 0)
        unless rooms.key? door[:dest]
          rebuilt_line = "#{door[:lock]} #{door[:key]} #{door[:dest]}"
          nb(door[:lock_line_number], rebuilt_line, "Door destination room is not in the area")
        end
      end
    end
  end

  def correlate_resets(resets, mobiles, objects, rooms)
    return if resets.nil?

    skipped_mobs, skipped_objects, skipped_rooms = 0, 0, 0

    # Here is yon scoop:
    # If there's no mobs/objects/rooms section in the area, their parameters
    # in this method will be nil. The correlate_whatever method checks for it
    # being nil, and if so returns a 1, otherwise it does its thing and returns
    # a 0.
    #
    # That result is added to skipped_whatever, and after all the checking is
    # complete we can post a N.B. saying "Since the section wasn't in the area,
    # we didn't check N resets to see if they pointed to something in the area."

    resets.each do |reset|
      case reset.type
      when :mobile
        skipped_mobs += correlate_mob_reset_vnum(reset, mobiles)
        skipped_rooms += correlate_mob_reset_room(reset, rooms)
      when :inventory
        skipped_objects += correlate_obj_reset_vnum(reset, objects)
      when :equipment
        skipped_objects += correlate_obj_reset_vnum(reset, objects)
      when :object
        skipped_objects += correlate_obj_reset_vnum(reset, objects)
        skipped_rooms += correlate_obj_reset_room(reset, rooms)
      when :container
        skipped_objects += correlate_obj_reset_vnum(reset, objects)
        skipped_objects += correlate_container_reset(reset, objects)
      when :door
        skipped_rooms += correlate_door_reset(reset, rooms)
      when :random
        skipped_rooms += correlate_random_reset(reset, rooms)
      end
    end

    if skipped_mobs > 0
      nb(resets.line_number, nil, "No MOBILES section in area, #{skipped_mobs} mob references in RESETS skipped")
    end
    if skipped_objects > 0
      nb(resets.line_number, nil, "No OBJECTS section in area, #{skipped_objects} object references in RESETS skipped")
    end
    if skipped_rooms > 0
      nb(resets.line_number, nil, "No ROOMS section in area, #{skipped_rooms} room references in RESETS skipped")
    end
  end

  def correlate_shops(shops, mobiles)
    return if shops.nil?
    if mobiles.nil?
      warn(shops.line_number, nil, "No MOBILES section in area, #{shops.length} mob references in SHOPS skipped")
      return
    end
    shops.each do |shop|
      unless mobiles.key? shop.vnum
        warn(shop.line_number, shop.vnum.to_s, "Shopkeeper mob is not in the area")
      end
    end
  end

  def correlate_specials(specials, mobiles)
    return if specials.nil?
    if mobiles.nil?
      nb(specials.line_number, nil, "No MOBILES section in area, #{specials.length} mob references in SPECIALS skipped")
      return
    end
    specials.each do |special|
      unless mobiles.key? special.vnum
        warn(special.line_number, special.line, "Spec_fun's mob is not in the area")
      end
    end
  end

  private

  # Checking specific reset references

  def correlate_mob_reset_vnum(reset, mobiles)
    return 1 if mobiles.nil?
    unless mobiles.key? reset.vnum
      warn(reset.line_number, reset.line, "Mobile to spawn is not in the area")
    end
    0
  end

  def correlate_mob_reset_room(reset, rooms)
    return 1 if rooms.nil?
    unless rooms.key? reset.target
      warn(reset.line_number, reset.line, "Mobile spawn location is not in the area")
    end
    0
  end

  def correlate_obj_reset_vnum(reset, objects)
    return 1 if objects.nil?
    unless objects.key?(reset.vnum) || known_vnum(reset.vnum)
      warn(reset.line_number, reset.line, "Object to spawn is not in the area")
    end
    0
  end

  def correlate_obj_reset_room(reset, rooms)
    return 1 if rooms.nil?
    unless rooms.key? reset.target
      warn(reset.line_number, reset.line, "Object spawn location is not in the area")
    end
    0
  end

  def correlate_container_reset(reset, objects)
    return 1 if objects.nil?
    unless objects.key? reset.target
      warn(reset.line_number, reset.line, "Object spawn container is not in the area")
    end
    0
  end

  def correlate_door_reset(reset, rooms)
    return 1 if rooms.nil?
    if rooms.key?(reset.vnum) == false
      err(reset.line_number, reset.line, "Door reset's room is not in the area")
    elsif rooms[reset.vnum].doors.nil?
      err(reset.line_number, reset.line, "Door reset's room does not have this exit")
    elsif rooms[reset.vnum].doors[reset.target].nil?
      err(reset.line_number, reset.line, "Door reset's room does not have this exit")
    elsif rooms[reset.vnum].doors[reset.target][:lock] == 0
      err(reset.line_number, reset.line, "Door reset targets an exit with no door")
    end
    0
  end

  def correlate_random_reset(reset, rooms)
    return 1 if rooms.nil?
    unless rooms.key? reset.vnum
      err(reset.line_number, reset.line, "Room to randomize isn't in the area")
    end
    0
  end

end
