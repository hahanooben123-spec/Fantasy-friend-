"""Build bundled original music and convert selected Kenney CC0 effects.
Development only: python -m pip install numpy soundfile
Download the official interface-sounds zip to tools/kenney_interface-sounds.zip.
No downloads or synthesis are needed in the shipped app.
"""
from pathlib import Path
import io, zipfile
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "FantasiVen.swiftpm/Resources/Audio"
RATE = 22050

def theme(name, bpm, transpose, dreamy=False):
    beat = 60 / bpm
    length = int(64 * beat * RATE)
    mix = np.zeros((length, 2), dtype=np.float64)
    def note(midi, start, duration, gain, pan=0, kind="pluck"):
        t = np.arange(int(duration * RATE)) / RATE
        hz = 440 * 2 ** ((midi + transpose - 69) / 12)
        if kind == "pad":
            env = np.sin(np.pi * t / duration) ** 2
            signal = np.sin(2*np.pi*hz*t) + .13*np.sin(2*np.pi*hz*2*t)
        else:
            env = (1-np.exp(-t/0.008)) * np.exp(-t/(.6 if dreamy else .32))
            env *= np.minimum(1, (duration-t)/.07)
            signal = np.sin(2*np.pi*hz*t) + .22*np.sin(2*np.pi*hz*2*t)*np.exp(-t/.18)
            signal += .07*np.sin(2*np.pi*hz*3*t)*np.exp(-t/.09)
        signal *= env*gain
        stereo = signal[:,None]*np.array([np.sqrt((1-pan)/2), np.sqrt((1+pan)/2)])
        indices = (int(start*RATE)+np.arange(len(t))) % length
        np.add.at(mix, indices, stereo)
    chords = [(48,52,55),(45,48,52),(53,57,60),(55,59,62)]
    motifs = [
        [(0,72),(1,76),(2.5,79),(4,76),(5.5,74)],
        [(0.5,72),(2,69),(3.5,72),(5,76),(6,79)],
        [(0,77),(1.5,76),(3,72),(4.5,69),(6,72)],
        [(0.5,74),(2,79),(3.5,77),(5,74),(6.5,71)],
        [(0,76),(1.5,79),(3,84),(5,79),(6.5,76)],
        [(0.5,76),(2,72),(4,69),(5.5,72)],
        [(0,77),(2,81),(3.5,79),(5,77),(6.5,76)],
        [(0,74),(1.5,71),(3,67),(4.5,72)]
    ]
    for phrase in range(8):
        chord = chords[phrase%4]
        for pitch in chord:
            note(pitch+12, phrase*8*beat, 9*beat, .045 if dreamy else .025, (pitch%3-1)*.4, "pad")
        for half in range(4):
            note(chord[0]-12, (phrase*8+half*2)*beat, 1.4*beat, .09, -.1)
            arp = chord[(half+phrase)%3]+12
            note(arp, (phrase*8+half*2+.75)*beat, 1.5*beat, .047, .45)
        for onset, pitch in motifs[phrase]:
            note(pitch, (phrase*8+onset)*beat, 2.8*beat, .14, -.2 if phrase%2 else .2)
            if dreamy:
                note(pitch+12, (phrase*8+onset+.08)*beat, 2.2*beat, .022, -.55)
        if not dreamy:
            for step in range(8):
                # Soft brush rather than sharp clicks.
                rng = np.random.default_rng(phrase*8+step)
                t = np.arange(int(.1*RATE))/RATE
                noise = rng.normal(0,1,len(t))
                noise = np.convolve(noise,np.ones(8)/8,mode="same")
                brush = noise*np.sin(np.pi*t/.1)**2*.022
                indices=(int((phrase*8+step+.5)*beat*RATE)+np.arange(len(t)))%length
                np.add.at(mix,indices,brush[:,None]*np.array([.8,.6]))
    # Circular echoes carry tails across the loop boundary, preventing a cut at restart.
    dry=mix.copy()
    mix += .20*np.roll(dry,int(.375*beat*RATE),axis=0)[:,::-1]
    mix += .09*np.roll(dry,int(.75*beat*RATE),axis=0)
    mix *= .72/max(.72,float(np.max(np.abs(mix))))
    sf.write(OUT/(name+".wav"),mix,RATE,subtype="PCM_16")

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    theme("music_garden",88,0)
    theme("music_dream",72,0,True)
    theme("music_workshop",88,0)
    archive=ROOT/"tools/kenney_interface-sounds.zip"
    with zipfile.ZipFile(archive) as z:
        for name in ["click_001","click_002","click_003","pluck_001","pluck_002","drop_001","confirmation_001"]:
            audio,rate=sf.read(io.BytesIO(z.read("Audio/"+name+".ogg")),always_2d=True)
            # Retain the original timbre; soften edges and standardize peak headroom.
            edge=min(int(rate*.006),len(audio)//2)
            if edge:
                audio[:edge]*=np.linspace(0,1,edge)[:,None]
                audio[-edge:]*=np.linspace(1,0,edge)[:,None]
            peak=float(np.max(np.abs(audio)))
            if peak>0: audio*=.65/peak
            sf.write(OUT/("kenney_"+name+".wav"),audio,rate,subtype="PCM_16")
        license_dir=ROOT/"Documentation/Audio"
        license_dir.mkdir(parents=True,exist_ok=True)
        (license_dir/"Kenney-License.txt").write_bytes(z.read("License.txt"))
    print("Created three original looping themes and seven CC0 effects.")

if __name__=="__main__":
    main()
