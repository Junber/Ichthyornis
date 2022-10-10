eval_file KNOBS_RB_PATH()
eval_file PADS_RB_PATH()

use_debug false

controlTime = 0.5
controlSlideTime = 0.5

initKnobs
initPads


# Pads
# (PAD) Start Pluck, Start Slow
# (Prog Chng) Note, Slowness, Slow Pausing, Noise Randomness
setPadRanges(-4,3, 1,10, 0,10, 0,6)

# Knobs
# Pulse Amp, Noise Amp, Pluck Amp, Slow Amp
# Sleep Mult, Slow Release, Pluck Krush Mix, Pluck Reverb Mix


#*************************************************************************************
# Pulse

with_fx :reverb, room: 1.0, mix: 0.6, amp: 0, slide: controlSlideTime do |rev|
  live_loop :pulseController do
    control rev, amp: getKnobNormalized(1)
    sleep controlTime
  end
  
  with_fx :tremolo, depth: 1, phase: 0.0007, wave: 3 do
    live_loop :pulse do
      use_synth_defaults sustain: 3, release: 1, attack: 1, cutoff: 30
      for i in range(1, 8)
        synth :pulse, note: (rrand :C1, :C9), pulse_width: 1 - 0.1 ** i
      end
      sleep 1
    end
  end
end



#*************************************************************************************
# Noise

with_fx :reverb, mix: 0.7, damp: 1.0, amp: 0, slide: controlSlideTime do |rev|
  live_loop :noiseController do
    control rev, amp: getKnobNormalized(2)
    sleep controlTime
  end
  
  oldCutoff = -1
  live_loop :noise do
    cutoff = (rrand_i 130 - getPad(4) * 20, 130)
    oldCutoff = cutoff if oldCutoff == -1
    use_synth_defaults sustain: 3.0, release: 0.0, cutoff: oldCutoff, slide: (rrand 1.0, 3.0)
    
    a = synth :gnoise, amp: 0.4
    b = synth :bnoise, amp: 1.0
    c = synth :cnoise, amp: 0.2
    
    control a, cutoff: cutoff
    control b, cutoff: cutoff
    control c, cutoff: cutoff
    oldCutoff = cutoff
    sleep 3.0
  end
end



#*************************************************************************************
# Pluck

live_loop :timer do
  cue :slowBeat
  getPad(2).times do
    cue :beat
    sleep (getKnob(5) + 30) / 200.0
  end
end

curScale = (scale :C5, :jiao)

set :loopNum, 0

define :startLoop do |time, coef, decay, offset, amp, pattern|
  sync :beat
  n = get :loopNum
  set :loopNum, n+1
  
  live_loop ("loop" + n.to_s).to_sym do
    use_synth :pluck
    n = getPad(1) * 12 + offset
    play n, coef: coef, pluck_decay: decay, amp: amp if pattern.tick and n > 0
    time.times do
      sync :beat
    end
  end
end


with_fx :reverb, room: 1.0, mix: 0, slide: controlSlideTime do |rev|
  with_fx :krush, cutoff: 130, mix: 0, amp: 0, slide: controlSlideTime do |krush|
    live_loop :pluckController do
      control rev, mix: getKnobNormalized(8)
      control krush, mix: getKnobNormalized(7), amp: getKnobNormalized(3)
      sleep controlTime
    end
    
    live_loop :pluckSpawner do
      use_real_time
      note, strength = sync PAD_MIDI_NAME() + "note_on"
      if note == 36
        coef = (rrand 0.3, 0.9)
        offset = (choose curScale) + (knit 0,5,  -12,2).choose
        decay = (knit 100,5,  10,2, 20,1).choose
        
        amp = (rrand 1.0, 1.5) * coef * coef * coef + offset * 0.02 - 0.8
        amp = 0.1 if amp < 0.1
        
        in_thread do
          use_sched_ahead_time 1
          startLoop (rrand_i 2,5),  coef, decay, offset, amp, (spread (rrand_i 2,7), (rrand_i 7,11))
        end
      end
    end
  end
end


#*************************************************************************************
# Slow Melody

fxs = fx_names.to_a
# Fundamentally unsuited:
fxs.delete(:record)
fxs.delete(:sound_out)
fxs.delete(:sound_out_stereo)
fxs.delete(:level)
fxs.delete(:pan)
fxs.delete(:normaliser)
fxs.delete(:nbpf)
fxs.delete(:nhpf)
fxs.delete(:nlpf)
fxs.delete(:nrbpf)
fxs.delete(:nrhpf)
fxs.delete(:nrlpf)
fxs.delete(:eq)
# Not so great here:
fxs.delete(:bitcrusher)
fxs.delete(:krush)

synths = synth_names.to_a
# Fundamentally unsuited:
synths.delete(:sound_in)
synths.delete(:sound_in_stereo)
# Not so great here:
synths.delete(:bass_highend)
synths.delete(:mod_beep)
synths.delete(:mod_dsaw)
synths.delete(:mod_fm)
synths.delete(:mod_pulse)
synths.delete(:mod_saw)
synths.delete(:mod_sine)
synths.delete(:mod_tri)

amps = [
  [:blade, 0.1],
  [:bnoise, 0.3],
  [:chipbass, 0.15],
  [:chiplead, 0.5],
  [:chipnoise, 0.3],
  [:cnoise, 0.3],
  [:dull_bell, 0.5],
  [:dpluse, 0.3],
  [:dsaw, 0.3],
  [:dtri, 0.3],
  [:gnoise, 0.3],
  [:growl, 0.5],
  [:hoover, 0.3],
  [:fm, 0.5],
  [:hoover, 0.5],
  [:pluck, 0.3],
  [:pretty_bell, 0.1],
  [:saw, 0.4],
  [:tb303, 0.15],
]

define :start do |syn, pan_side|
  sync :slowBeat
  time_mult = (knit 4,5, 2,20, 1,3).choose
  melody = []
  a = amps.assoc(syn)
  mult = a == nil ? 1 : a[1]
  for i in range 0, (rrand_i 3, 5)
    melody.push([(choose curScale), (rrand 0.5, 1.0) * mult, (choose knit 2,5, 3,4) * time_mult])
  end
  pan = (rrand 0, 0.8) * pan_side
  fx = choose fxs
  
  amp = 3
  if fx == :tanh
    amp = 1
  end
  
  print syn, fx
  
  with_fx fx do
    pausing = false
    live_loop ("slowMelody" + syn.to_s).to_sym do
      prob = getPad(3)
      prob = 10 - prob if pausing
      pausing = !pausing if (vt > 10 and one_in(prob))
      for m in melody
        n = getPad(1) * 12 + m[0]
        synth syn,
          note: n, cutoff: n,
          amp: m[1], pan: pan, release: getPad(2) * 5 * getKnobNormalized(6), env_curve: 6 unless pausing
        
        m[2].times do
        sync :slowBeat
      end
    end
    sync :slowBeat
  end
end
end

with_fx :reverb, room: 1.0, mix: 0, amp: 0, slide: controlSlideTime do |rev|
  live_loop :slowMelodyController do
    control rev, mix: getKnobNormalized(8), amp: getKnobNormalized(4)
    sleep controlTime
  end
  
  live_loop :slowMelodySpawner do
    use_real_time
    note, strength = sync PAD_MIDI_NAME() + "note_on"
    if note == 37
      t = tick
      in_thread do
        use_sched_ahead_time 1
        start synths[t % synths.length], (ring 0, 1, -1)[t]
      end
    end
  end
end