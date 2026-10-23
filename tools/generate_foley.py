"""Render original offline Foley-inspired game sounds; Python standard library only."""
from pathlib import Path
import math, random, struct, wave
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"FantasiVen.swiftpm/Resources/Audio"
RATE=22050
DURATIONS={"pour_flour":.85,"pour_water":.95,"pour_oil":.8,"mix":.28,"oven":.9,
           "munch":.27,"bubble":.19,"catch":.28,"bounce":.22}
def render(name,duration):
    rng=random.Random(671+len(name))
    samples=[]
    low=0.0
    phase=0.0
    for i in range(int(RATE*duration)):
        t=i/RATE;p=t/duration
        low=.72*low+.28*rng.uniform(-1,1)
        env=min(1,t/.015)*min(1,(duration-t)/.03)
        if name=="pour_flour":
            value=low*.25*(.7+.3*math.sin(t*37))
        elif name in ("pour_water","pour_oil"):
            speed=13 if name=="pour_water" else 8
            pulse=(t*speed)%1
            hz=(700 if name=="pour_water" else 330)*(1-pulse*.65)
            phase+=2*math.pi*hz/RATE
            value=.20*math.sin(phase)*math.exp(-pulse*7)+low*.08
        elif name=="mix":
            value=low*.30*(.3+.7*math.sin(math.pi*p)**2)
        elif name=="oven":
            value=low*.15*(.75+.25*math.sin(t*19))+.015*math.sin(t*math.pi*2*85)
        elif name=="munch":
            crunch=math.exp(-((p-.18)/.10)**2)+.7*math.exp(-((p-.59)/.13)**2)
            value=(rng.uniform(-1,1)*.18+low*.25)*crunch
        elif name=="bubble":
            phase+=2*math.pi*(1100*math.exp(-p*4)+130)/RATE
            value=math.sin(phase)*math.exp(-p*5)*.40
        elif name=="catch":
            value=(math.sin(2*math.pi*(660 if p<.45 else 880)*t)*.20)*math.sin(math.pi*p)**2
        else:
            phase+=2*math.pi*(160*math.exp(-p*7)+65)/RATE
            value=math.sin(phase)*math.exp(-p*5)*.35
        samples.append(struct.pack("<h",int(max(-1,min(1,value*env))*24000)))
    with wave.open(str(OUT/("foley_"+name+".wav")),"wb") as output:
        output.setnchannels(1);output.setsampwidth(2);output.setframerate(RATE)
        output.writeframes(b"".join(samples))
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    for name,duration in DURATIONS.items():render(name,duration)
    print("Created nine original contextual game sounds.")
if __name__=="__main__":main()
