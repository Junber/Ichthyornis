midi_name = PAD_MIDI_NAME()

define :initPads do
  for i in range 1, 5
    set ("pad" + i.to_int.to_s).to_sym, 0
  end
end

lows = [0,0,0,0]
highs = [1,1,1,1]

define :setPadRanges do |low1, high1, low2, high2, low3, high3, low4, high4|
  lows = [low1, low2, low3, low4]
  highs = [high1, high2, high3, high4]
  
  for i in range 1, 5
    pad = ("pad" + i.to_int.to_s).to_sym
    val = get pad
    
    if val < lows[i-1]
      set pad, lows[i-1]
    end
    if val > highs[i-1]
      set pad, highs[i-1]
    end
  end
end

define :getPad do |i|
  return get ("pad" + i.to_int.to_s).to_sym
end

live_loop :midi_buttons do
  use_real_time
  prog, value = sync midi_name + "program_change"
  
  i = (prog >= 4 ? prog - 4 : prog)
  pad = ("pad" + (i  + 1).to_int.to_s).to_sym
  val = get pad
  
  if prog >= 4
    if val < highs[i]
      set pad, val + 1
    end
  else
    if val > lows[i]
      set pad, val - 1
    end
  end
end