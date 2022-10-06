midi_name = PAD_MIDI_NAME()

define :initKnobs do
  set :knobSet, 0
  for i in range 1, 9
    for u in range 1, 9
      set ("knobs" + i.to_int.to_s + u.to_int.to_s).to_sym, 0
    end
  end
end

define :printKnobs do
  print "Active KnobSet: " + (get :knobSet).to_s
  for i in range 1, 9
    s = ""
    for u in range 1, 9
      s += (get ("knobs" + i.to_int.to_s + u.to_int.to_s).to_sym).to_s + ", "
    end
    print s
  end
end

define :getKnob do |i, u|
  return get ("knobs" + i.to_int.to_s + u.to_int.to_s).to_sym
end

define :getKnobNormalized do |i, u|
  return getKnob(i, u) / 127.0
end

live_loop :midi_knobs do
  use_real_time
  knob, value = sync midi_name + "control_change"
  
  if get(:knobSet) == 0
    for i in range 1, 9
      set ("knobs" + i.to_int.to_s + knob.to_int.to_s).to_sym, value
    end
  else
    set ("knobs" + get(:knobSet).to_int.to_s + knob.to_int.to_s).to_sym, value
  end
end

live_loop :midi_buttons do
  use_real_time
  prog, value = sync midi_name + "program_change"
  
  if get(:knobSet) == prog + 1
    set :knobSet, 0
  else
    set :knobSet, prog + 1
  end
end