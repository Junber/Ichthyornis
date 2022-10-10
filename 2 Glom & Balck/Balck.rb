use_debug false
use_bpm 60
use_sched_ahead_time 1.0

use_random_seed 1

define :inSecondPart do |premature = false|
  return ((premature and bt(vt) >= 570 and vt <= 570) or vt >= 600)
end

live_loop :secondPartAnnounced do
  sleep 1
  if inSecondPart
    cue :secondPartStart
    stop
  end
end


############### Beats

#inputArgs = [ampMult, panOffset, releaseHeadStart, octaves, note_offset]
define :synthArgs do |inputArgs, beatSleepRatio|
  amp = (rrand 0.2, 0.3) + beatSleepRatio
  pan = rrand -0.3, 0.3
  note = (rrand :C4, :C4 + 12 * inputArgs[3]) + inputArgs[4]
  rand_back
  niceNote = (chord :C2, :minor7, num_octaves: inputArgs[3] - 1).choose + inputArgs[4]
  curSynth = [:saw, :square, :tri].choose
  release = 0.005 * (12 + (tick(:release) + inputArgs[2]) ** 2)
  return [amp * inputArgs[0], pan + inputArgs[1], curSynth, note, niceNote, release], curSynth == :square
end

#args = [amp, pan, synth, note, niceNote, release]
define :playSynth do |args|
  synth args[2],
    amp: (args[0] + (rrand -0.05, 0.05)) * (inSecondPart ? 1.3 : 1),
    pan: args[1] + (rrand -0.05, 0.05),
    note: ((inSecondPart true) ? args[4] : args[3]),
    release:  ((inSecondPart true) ? Math.sqrt(args[5]) : args[5])
end

set :loopNum, 0
define :startBeatLoop do |real, funcs, inputArgs, hitsPerBeat, beatTime, stopSig, beatSleepTime, timeMult = 1.0, offset = 0.0, alwaysPlay=false|
  n = get :loopNum
  set :loopNum, n+1
  set :activeLoops, n+1 if real # Kind of a hack. In general, real and non-real loops would have to be counted seperately but here this works
  
  live_loop ("loop" + stopSig.to_s + n.to_s).to_sym do #The loop name is rather hacky...
    atTimes = range offset, timeMult * beatTime + offset - 0.0001, step: beatSleepTime   # - 0.0001 accounts for floating point inaccuracies...
    
    beatsLength = (rrand_i 200, 400) / atTimes.length / (alwaysPlay ? 4 : 1)
    
    args, notTooLong = send(funcs[0], inputArgs, beatSleepTime / beatTime)
    
    timing = spread (rrand_i 2, 4), (one_in(3) ? hitsPerBeat * (rrand_i 1, 4) : (rrand_i 8, 11))
    timing = ring true if alwaysPlay
    
    beatsLength = beatsLength / 3 if notTooLong
    beatsLength = 1 if beatsLength < 1
    
    metaTiming = ((one_in(4) or alwaysPlay) ? (ring true) : (spread (rrand_i 3, 7), (rrand_i 8, 11)))
    
    idxOffset = 0
    beatsLength.times do
      if metaTiming.tick(:metaTiming)
        at atTimes do |t, idx|
          send(funcs[1], args) if timing[idxOffset + idx]
        end
        
        idxOffset += atTimes.length
      end
      sleep beatTime
      use_bpm get :bpm
      while real and n < get(:loopNum) - get(:activeLoops)
        metaTiming.tick(:metaTiming)
        idxOffset += atTimes.length
        sleep beatTime
        use_bpm get :bpm
      end
      stop if get(stopSig)
      cue :beatTick if alwaysPlay and real # alwaysPlay is only true for one thread with hitsPerBeat=1
    end
  end
end

define :startBeatLoops do |real, funcs, commonArgs, rareArgs, timeSigUpper, timeSigLower, force, scaleCoef|
  stopSig = ("stop" + timeSigLower.to_s + " " + timeSigUpper.to_s).to_sym
  
  set stopSig, false
  print "Changing time to " + timeSigUpper.to_s + " over " + timeSigLower.to_s +
    " (force " + force.to_s + ", scaleCoef " + scaleCoef.to_s + ")"
  
  beatTime = timeSigUpper.to_f / timeSigLower
  
  i = 1
  while i < timeSigUpper
    hitsPerBeat = (timeSigUpper / i).to_i
    beatSleepTime = beatTime * i / timeSigUpper
    timeMult = hitsPerBeat * i.to_f / timeSigUpper
    
    curArgs = i > 2 ? rareArgs : commonArgs
    
    force.times do
    startBeatLoop real, funcs, curArgs, hitsPerBeat, beatTime, stopSig, beatSleepTime, timeMult
  end
  force.times do
    startBeatLoop real, funcs, curArgs, hitsPerBeat, beatTime, stopSig, beatSleepTime, timeMult, beatTime * (1.0 - timeMult)
  end
  
  i *= scaleCoef
end

startBeatLoop real, funcs, commonArgs, 1, beatTime, stopSig, beatTime, 1.0, 0.0, true
force.times do
  startBeatLoop real, funcs, rareArgs, 1, beatTime, stopSig, beatTime
end
end

funcs = [:synthArgs, :playSynth]
args = [1.0, 0.0, 0, 5, 0]
with_fx :distortion do |dist|
  with_fx :reverb, mix: 0.7 do |rev|
    with_fx :bitcrusher, bits: 3, sample_rate: 44100 do |bit|
      startBeatLoops true, funcs, args, args,
        8, 10,
        4, 2
      
      in_thread do
        sync :secondPartStart
        control dist, mix: 0
        control rev, mix: 0
        control bit, mix: 0
        
        sleep 10
        sync :beatTick
        with_fx :level, amp: 0, slide: 5 do |level|
          with_fx :reverb, mix: 0.7 do
            print "Bassing"
            control level, amp: 1
            args = [0.15, 0.0, 100, 4, -12]
            startBeatLoops false, funcs, args, args,
              4, 5,
              2, 2
            
            live_loop :revNoise do
              synth :bnoise, cutoff: 100, release: 0, sustain: 5, amp: 0.3
              sleep 5
            end
          end
          
          sleep 10
          with_fx :reverb, mix: 0.7 do
            print "Oceaning"
            
            live_loop :oceans do
              amp = tick(:amp) * 0.15 + (rrand 0.2, 0.3)
              extra_cutoff = 5 * (amp - 1.0)
              extra_sustain = 0.5 * (extra_cutoff - 30)
              extra_sustain = extra_sustain.min(0)
              extra_cutoff = extra_cutoff.min(0).max(30)
              amp = amp.min(0).max(1)
              s = synth [:bnoise, :cnoise, :gnoise].choose,
                amp: amp,
                attack: (rrand 1, 4), sustain: (rrand 1, 2) + extra_sustain, release: (rrand 2, 5),
                cutoff_slide: (rrand 0, 5), cutoff: (rrand 80, 100) + extra_cutoff,
                pan_slide: (rrand 1, 5), pan: (rrand -0.5, 0.5)
              
              control s, pan: (rrand -0.5, 0.5), cutoff: (rrand 70, 100) + extra_cutoff
              sleep (rrand 2, 3)
            end
            
            sleep 200
            print "De-Oceaning"
            control level, slide: 20
            control level, amp: 0
            sleep 20
            print "Reverbing"
            control rev, slide: 60
            control rev, mix: 1, room: 1, amp: 0.5
            sleep 60
            print "Fading"
            control rev, slide: 30
            control rev, pre_amp: 0
            sleep 30
            print "The End"
          end
        end
      end
      
    end
  end
end


############### Changing BPM n stuff

beatTime = 8.0/10
set :bpm, current_bpm

print "Active Loops", get(:activeLoops)
print "BPM", current_bpm

in_thread do
  sleep beatTime / 2 + beatTime * 10
  live_loop :changer do
    if one_in(get(:activeLoops) / 6 + 2)
      activeLoop = 0
      loops = get(:loopNum)
      if inSecondPart
        activeLoop = [(rrand_i loops/2, loops), loops].choose
      else
        activeLoop = [(rrand_i 0, loops), loops].choose
      end
      set :activeLoops, activeLoop
      print "Active Loops", activeLoop
    end
    if one_in(20)
      if inSecondPart
        x = (rrand_i 40, 70)
      else
        x = (rrand_i 40, 90)
      end
      set :bpm, x
      print "BPM", x
      sleep beatTime / 2
      use_bpm x
      sleep beatTime / 2
    end
    sleep beatTime
  end
end


############### Noises

for s in sample_names :loop
  load_sample s
end

define :melody do |mult|
  cur_sample = choose sample_names :loop
  cur_rate = mult * (rrand 10.0, 100.0)
  sd = sample_duration cur_sample, rate: cur_rate
  sd = 0.1 if sd < 0.1
  pan = rrand -0.8, 0.8
  cutoff = rrand 100, 130
  time = (rrand 2.0, 6.0)
  time = sd if time < sd
  at range(0.5, time + 0.5, step: sd) do
    sample cur_sample, rate: cur_rate, pan: pan, cutoff: cutoff
  end
  sleep time
  stop if inSecondPart
end

in_thread do
  with_fx :reverb, mix: 0.7, damp: 1.0, amp: 0.7 do |rev|
    with_fx :pitch_shift, pitch: 12, window_size: 0.01, time_dis: 0.0005, mix: 0.125 do
      with_fx :pitch_shift, pitch: 12, window_size: 0.01, time_dis: 0.0005, mix: 0.125 do
        with_fx :pitch_shift, pitch: 12, window_size: 0.01, time_dis: 0.0005, mix: 0.125 do
          with_fx :pitch_shift, pitch: 12, window_size: 0.01, time_dis: 0.0005, mix: 0.125 do
            in_thread do
              sync :secondPartStart
              control rev, amp: 0
            end
            
            10.times do
              live_loop (("loopFast" + tick.to_s).to_sym) do
                melody 1
              end
              live_loop (("loopSlow" + look.to_s).to_sym) do
                melody 0.001
              end
              sleep 10
            end
          end
        end
      end
    end
  end
end

in_thread do
  with_fx :reverb, mix: 0.7, damp: 1.0 do
    20.times do |i|
      live_loop (("loopSlowDifferent" + i.to_s).to_sym) do
        melody 0.001
      end
      sleep 1
    end
  end
end