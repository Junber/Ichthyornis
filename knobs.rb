midi_name = PAD_MIDI_NAME()

define :initKnobs do
  for i in range 1, 9
    set ("knobs" + i.to_int.to_s).to_sym, 0
  end
end

define :getKnob do |i|
  return get ("knobs" + i.to_int.to_s).to_sym
end

define :getKnobNormalized do |i|
  return getKnob(i) / 127.0
end

live_loop :midi_knobs do
  use_real_time
  knob, value = sync midi_name + "control_change"
  
  set ("knobs" + knob.to_int.to_s).to_sym, value
end