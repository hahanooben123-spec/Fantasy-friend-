import Foundation

/// Original, offline instrument voices. The result is mono, 16-bit PCM WAV.
enum InstrumentSynth {
    static func render(row:Int,beat:Int,voice:Int)->Data {
        let instrument=min(2,max(0,row))
        let voiceIndex=min(2,max(0,voice))
        let sampleRate=22050
        let duration=instrument == 0 ? 0.25 : instrument == 1 ? 0.48 : 0.34
        let count=Int(Double(sampleRate)*duration)
        let scale=[1.0,1.125,1.25,1.5,1.6667]
        let note=scale[((beat%5)+5)%5]
        let root=[220.0,330.0,165.0][voiceIndex]
        var noise:UInt32=8731
        var pcm=Data(capacity:count*2)
        for i in 0..<count {
            let t=Double(i)/Double(sampleRate)
            let value:Double
            if instrument == 0 {
                noise = 1664525 &* noise &+ 1013904223
                let hiss=Double(noise&0xFFFF)/32768-1
                let phase=2*Double.pi*(52*t+8*(1-exp(-22*t)))
                value=(sin(phase)*exp(-18*t)*0.8+hiss*exp(-40*t)*0.2)*min(1,t/0.002)
            } else if instrument == 1 {
                let frequency=261.63*note*(voiceIndex == 1 ? 1.25 : 1)
                let fundamental=sin(2*Double.pi*frequency*t)
                let overtone=0.3*sin(2*Double.pi*frequency*2.76*t)
                let sparkle=0.12*sin(2*Double.pi*frequency*5.4*t)
                value=(fundamental+overtone+sparkle)*exp(-7*t)*min(1,t/0.004)*0.7
            } else {
                let phase=2*Double.pi*root*note*t+0.11*sin(2*Double.pi*5*t)
                let vowel=0.55*sin(phase)+0.23*sin(2*phase)+0.12*sin(3*phase)+0.07*sin(5*phase)
                value=vowel*min(1,t/0.025)*pow(max(0,1-t/duration),1.4)
            }
            append(Int16(max(-1,min(1,value))*11000),to:&pcm)
        }
        var data=Data("RIFF".utf8)
        append(UInt32(36+pcm.count),to:&data);data.append(Data("WAVEfmt ".utf8))
        append(UInt32(16),to:&data);append(UInt16(1),to:&data);append(UInt16(1),to:&data)
        append(UInt32(sampleRate),to:&data);append(UInt32(sampleRate*2),to:&data)
        append(UInt16(2),to:&data);append(UInt16(16),to:&data)
        data.append(Data("data".utf8));append(UInt32(pcm.count),to:&data);data.append(pcm)
        return data
    }
    private static func append<T:FixedWidthInteger>(_ value:T,to data:inout Data) {
        var little=value.littleEndian
        withUnsafeBytes(of:&little) {data.append(contentsOf:$0)}
    }
}
