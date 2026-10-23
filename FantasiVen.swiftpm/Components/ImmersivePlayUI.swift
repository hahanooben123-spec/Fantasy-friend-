import SwiftUI

struct PlayHUD: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    let title:String
    let hint:String
    @Binding var paused:Bool
    @State private var settings=false
    @State private var wasPaused=false
    var body:some View {
        HStack(spacing:8) {
            RoundButton(icon:"chevron.left",label:store.t("close")) {presentation.wrappedValue.dismiss()}
            Text(title).font(.system(size:18,weight:.heavy,design:.rounded)).lineLimit(1).minimumScaleFactor(0.7)
                .padding(.horizontal,12).padding(.vertical,10).background(StorybookPanel(cornerRadius:24))
            Spacer(minLength:0)
            RoundButton(icon:"slider.horizontal.3",label:store.t("settings")) {wasPaused=paused;paused=true;settings=true}
            RoundButton(icon:paused ? "play.fill" : "pause.fill",label:store.t(paused ? "resumeGame" : "pauseGame")) {paused.toggle()}
        }.padding(.horizontal,12).padding(.top,8)
            .sheet(isPresented:$settings) {
                ZStack {
                    WorldBackdrop(world:.clouds,animated:false)
                    VStack(spacing:24) {
                        Text(title).font(.system(.title,design:.rounded).weight(.heavy))
                        Text(hint).font(.system(.title3,design:.rounded)).multilineTextAlignment(.center)
                        FlowerDifficulty()
                        CandyButton(title:store.t("help"),icon:"speaker.wave.2.fill") {
                            SoundService.shared.speak(hint,language:store.settings.language)
                        }
                        CandyButton(title:store.t("continue"),icon:"checkmark") {settings=false}
                    }.padding(28).frame(maxWidth:480)
                }
            }.onChange(of:settings) { value in if !value {paused=wasPaused} }
    }
}
struct PlayPauseOverlay:View {
    @EnvironmentObject private var store:FriendStore
    var resume:()->Void
    var body:some View {
        ZStack {
            Color.indigo.opacity(0.4).ignoresSafeArea()
            VStack(spacing:20) {
                CloudArtwork().frame(width:100,height:80)
                CandyButton(title:store.t("resumeGame"),icon:"play.fill",action:resume)
            }.padding(28).frame(maxWidth:340).background(StorybookPanel(cornerRadius:36))
        }
    }
}
struct PlayDock<Content:View>:View {
    var spacing:CGFloat=8
    @ViewBuilder var content:()->Content
    var body:some View {
        HStack(spacing:spacing,content:content).padding(12)
            .background(StorybookPanel(cornerRadius:28))
            .shadow(color:GameStyle.ink.opacity(0.15),radius:12,y:5)
            .padding(.horizontal,12).padding(.bottom,12)
    }
}
struct PlayToken:View {
    let symbol:String
    let label:String
    var selected=false
    var action:()->Void
    var body:some View {
        Button(action:action) {
            VStack(spacing:2) {
                PlayControlArtwork(symbol:symbol).frame(width:38,height:38)
                Text(label).font(.system(size:12,weight:.heavy,design:.rounded)).lineLimit(2).multilineTextAlignment(.center)
            }.frame(minWidth:52,minHeight:66)
                .background { if selected {CandySurface(color:StorybookStyle.honey,cornerRadius:18)} }
        }.buttonStyle(SquishStyle()).accessibilityLabel(label)
    }
}
struct PlayCelebration:View {
    let revision:Int
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var start=Date.distantPast
    @State private var animating=false
    var body:some View {
        TimelineView(.animation(minimumInterval:1.0/30,paused:!animating)) { timeline in
            let progress=timeline.date.timeIntervalSince(start)/1.1
            Canvas { canvas,size in
                guard progress>=0 && progress<1 else {return}
                for i in 0..<24 {
                    let x=CGFloat((i*47+13)%100)/100*size.width
                    let y=CGFloat(progress)*size.height*0.75+CGFloat((i*29)%80)
                    let side=CGFloat(6+i%5)
                    let rect=CGRect(x:x,y:y,width:side,height:side*1.8)
                    canvas.fill(Path(roundedRect:rect,cornerRadius:2),with:.color(GameStyle.palette[i%16].opacity(1-progress)))
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
            .task(id:revision) {
                guard revision>0,!reduced else {animating=false;return}
                start=Date();animating=true
                do {try await Task.sleep(nanoseconds:1_200_000_000)} catch {return}
                animating=false
            }
    }
}

