eval_file MULTI_KNOBS_RB_PATH()

#initKnobs

use_debug false

loopLen = 5.0
fxControlTime = 0.5

midi_name = PAD_MIDI_NAME()

buf1 = buffer :buffer1, loopLen
buf2 = buffer :buffer2, loopLen

pianoKnobs = 1 # PlaybackAmp, Amp, Note, Pan
pitchShiftKnobs = 2 #Mix, Pitch, Window Size, Pitch Dis, Time Dis
bitcrusherKnobs = 3 #Mix, SampleRate, Bits
reverbKnobs = 4 #Mix, Room, Damp
echoKnobs = 5 #Inner(Top), Outer(Bottom): Mix, Phase, Decay
krushKnobs = 6 #Mix, Gain, Cutoff, Res
innerHPFKnobs = 7 #LPF(Top), HPF(Bottom): Mix, Cutoff, Res
outerHPFKnobs = 8 #LPF(Top), HPF(Bottom): Mix, Cutoff, Res

# Effects to add: Octaver, GVerb instead of Reverb?, ...

with_fx :level, amp: 0 do
  live_loop :record do
    with_fx :record, buffer: [buf1, buf2].tick do
      live_audio :loop, input: 1, stereo: true
      sleep loopLen
    end
  end
end

live_loop :reporter do
  printKnobs
  sleep 10
end

with_fx :rlpf, slide: fxControlTime do |outerLPF|
  with_fx :rhpf, slide: fxControlTime do |outerHPF|
    with_fx :echo, slide: fxControlTime do |outerEcho|
      with_fx :bitcrusher, slide: fxControlTime do |bitcrusher|
        with_fx :reverb, slide: fxControlTime do |rev|
          with_fx :krush, slide: fxControlTime do |krush|
            with_fx :pitch_shift, slide: fxControlTime do |pitchShift|
              with_fx :echo, slide: fxControlTime do |innerEcho|
                with_fx :rlpf, slide: fxControlTime do |innerLPF|
                  with_fx :rhpf, slide: fxControlTime do |innerHPF|
                    
                    with_fx :level, slide: fxControlTime do |inputLevel|
                      live_loop :playbackController do
                        control inputLevel, amp: getKnobNormalized(pianoKnobs, 1) * 10.0
                        sleep fxControlTime
                      end
                      live_loop :playback do
                        s = sample [buf2, buf1].tick, amp: 10
                        sleep loopLen
                      end
                    end
                    
                    live_loop :pitchShiftController do
                      control pitchShift,
                        mix: getKnobNormalized(pitchShiftKnobs, 1),
                        pitch: getKnobNormalized(pitchShiftKnobs, 2) * 48 - 24,
                        window_size: Math.sqrt(getKnobNormalized(pitchShiftKnobs, 3)) + 6e-5,
                        pitch_dis: Math.sqrt(getKnobNormalized(pitchShiftKnobs, 4) * 10),
                        time_dis: Math.sqrt(getKnobNormalized(pitchShiftKnobs, 5) * 10)
                      sleep fxControlTime
                    end
                    
                    live_loop :bitcrusherController do
                      knob2 = getKnobNormalized(bitcrusherKnobs, 2)
                      
                      control bitcrusher,
                        mix: getKnobNormalized(bitcrusherKnobs, 1),
                        sample_rate: 10 + knob2 * knob2 * knob2 * 10000,
                        bits: 1 + getKnobNormalized(bitcrusherKnobs, 3) * 9
                      sleep fxControlTime
                    end
                    
                    live_loop :reverbController do
                      control rev,
                        mix: getKnobNormalized(reverbKnobs, 1),
                        room: getKnobNormalized(reverbKnobs, 2),
                        damp: getKnobNormalized(reverbKnobs, 3)
                      sleep fxControlTime
                    end
                    
                    live_loop :innerEchoController do
                      decay = getKnobNormalized(echoKnobs, 3) * 100 + 0.01
                      decay = 10000000 if decay == 100.01
                      control innerEcho,
                        mix: getKnobNormalized(echoKnobs, 1),
                        phase: getKnobNormalized(echoKnobs, 2) * 10 + 0.01,
                        decay: decay
                      sleep fxControlTime
                    end
                    
                    live_loop :outerEchoController do
                      decay = getKnobNormalized(echoKnobs, 7) * 100 + 0.01
                      decay = 10000000 if decay == 100.01
                      control outerEcho,
                        mix: getKnobNormalized(echoKnobs, 5),
                        phase: getKnobNormalized(echoKnobs, 6) * 10 + 0.01,
                        decay: decay
                      sleep fxControlTime
                    end
                    
                    live_loop :krushController do
                      control krush,
                        mix: getKnobNormalized(krushKnobs, 1),
                        gain: getKnobNormalized(krushKnobs, 2) * 50 + 1,
                        cutoff: getKnobNormalized(krushKnobs, 3) * 130,
                        res: getKnobNormalized(krushKnobs, 4) * 0.9999
                      sleep fxControlTime
                    end
                    
                    live_loop :innerHPFController do
                      control innerHPF,
                        mix: getKnobNormalized(innerHPFKnobs, 5),
                        cutoff: getKnobNormalized(innerHPFKnobs, 6) * 130,
                        res: getKnobNormalized(innerHPFKnobs, 7) * 0.9999
                      sleep fxControlTime
                    end
                    
                    live_loop :innerLPFController do
                      control innerLPF,
                        mix: getKnobNormalized(innerHPFKnobs, 1),
                        cutoff: getKnobNormalized(innerHPFKnobs, 2) * 130,
                        res: getKnobNormalized(innerHPFKnobs, 3) * 0.9999
                      sleep fxControlTime
                    end
                    
                    live_loop :outerHPFController do
                      control outerHPF,
                        mix: getKnobNormalized(outerHPFKnobs, 5),
                        cutoff: getKnobNormalized(outerHPFKnobs, 6) * 130,
                        res: getKnobNormalized(outerHPFKnobs, 7) * 0.9999
                      sleep fxControlTime
                    end
                    
                    live_loop :outerLPFController do
                      control outerLPF,
                        mix: getKnobNormalized(outerHPFKnobs, 1),
                        cutoff: getKnobNormalized(outerHPFKnobs, 2) * 130,
                        res: getKnobNormalized(outerHPFKnobs, 3) * 0.9999
                      sleep fxControlTime
                    end
                    
                    live_loop :midi_piano do
                      use_real_time
                      note, velocity = sync midi_name + "note_on"
                      in_thread do
                        start = vt
                        syncNote = note
                        note += getKnob(pianoKnobs, 3)
                        amp = velocity / 127.0 * getKnobNormalized(pianoKnobs, 2)
                        pan = getKnobNormalized(pianoKnobs, 4) * 2 - 1
                        c = synth synth_names[syncNote], note: note, amp: amp, pan: pan, slide: 0.2
                        loop do
                          newNote, velocity = sync midi_name + "note_off"
                          if newNote == syncNote
                            control c, amp: 0
                            break
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end