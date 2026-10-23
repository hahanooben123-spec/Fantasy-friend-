import SwiftUI

struct PathGameView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let friend:FantasyFriend
    @State private var puzzle=PathPuzzle(level:1)
    @State private var walking=false
    @State private var progress=0.0
    @State private var round=0
    @State private var celebration=0
    private func pathY(height:CGFloat)->CGFloat {
        let p=min(0.99999,max(0,progress))*4
        let i=Int(p),t=p-Double(i)
        let a=puzzle.target[max(0,i-1)],b=puzzle.target[i]
        let smooth=t*t*(3-2*t)
        return height*0.24+19+(0.25+(Double(a)+Double(b-a)*smooth)*0.25)*height*0.43-25
    }
    var body:some View {
        AdventureGameShell(kind:.path) {active in
            GeometryReader {proxy in
                ZStack {
                    HStack(spacing:0) {
                        ForEach(0..<4) {tile in
                            Button {
                                puzzle.turn(tile)
                                SoundService.shared.play(puzzle.tiles[tile] == puzzle.target[tile] ? .reaction : .click)
                            } label:{
                                VStack(spacing:12) {
                                    Text(puzzle.tiles[tile] == puzzle.target[tile] ? "🌸" : "↻")
                                        .font(.system(size:30,weight:.heavy,design:.rounded))
                                    PathTile(entry:tile == 0 ? puzzle.target[0] : puzzle.target[tile-1],exit:puzzle.tiles[tile])
                                        .frame(height:proxy.size.height*0.43)
                                }.contentShape(Rectangle())
                            }.buttonStyle(.plain).disabled(walking)
                                .accessibilityLabel(store.t("pathHelp")+" \(tile+1)")
                        }
                    }.frame(height:proxy.size.height*0.43+48)
                        .position(x:proxy.size.width/2,y:proxy.size.height*0.455)
                    DestinationArt(kind:.village).frame(width:120,height:110)
                        .position(x:proxy.size.width*0.84,y:proxy.size.height*0.2)
                    CharacterView(friend:friend,happy:progress>=1)
                        .frame(width:min(140,proxy.size.width*0.26),height:min(150,proxy.size.width*0.28))
                        .position(x:22+progress*(proxy.size.width-44),y:pathY(height:proxy.size.height))
                        .allowsHitTesting(false)
                    PlayCelebration(revision:celebration)
                    VStack {
                        Spacer()
                        Text(store.t(progress>=1 ? "wellDone" : "pathHelp"))
                            .font(.system(.headline,design:.rounded).weight(.heavy)).multilineTextAlignment(.center)
                            .padding(12).background(Capsule().fill(.white.opacity(0.92))).padding(.horizontal,20)
                        PlayDock {
                            Text(String(repeating:"🌸",count:zip(puzzle.tiles,puzzle.target).filter {$0.0 == $0.1}.count))
                                .font(.system(size:23)).frame(maxWidth:.infinity)
                            PlayToken(symbol:progress>=1 ? "🗺️" : "🎲",label:store.t("nextPuzzle")) {next()}
                        }
                    }
                }
            }
            .task(id:"\(active)-\(walking)") {
                guard active && walking && progress<1 else {return}
                while progress<1 && !Task.isCancelled {
                    progress=min(1,progress+(reduced ? 0.05 : 0.012))
                    do {try await Task.sleep(nanoseconds:reduced ? 150_000_000 : 33_333_333)} catch {return}
                }
                if !Task.isCancelled {celebration+=1;SoundService.shared.play(.complete)}
            }
        }.onAppear {puzzle=PathPuzzle(level:store.settings.challengeLevel)}
            .onChange(of:puzzle.complete) {complete in if complete {walking=true;progress=0}}
    }
    private func next() {
        round+=1;puzzle=PathPuzzle(level:store.settings.challengeLevel+round%3)
        progress=0;walking=false
    }
}
struct PathTile:View {
    let entry:Int
    let exit:Int
    var body:some View {
        Canvas {context,size in
            var path=Path()
            path.move(to:CGPoint(x:0,y:(0.25+Double(entry)*0.25)*size.height))
            path.addCurve(to:CGPoint(x:size.width,y:(0.25+Double(exit)*0.25)*size.height),
                control1:CGPoint(x:size.width*0.45,y:(0.25+Double(entry)*0.25)*size.height),
                control2:CGPoint(x:size.width*0.55,y:(0.25+Double(exit)*0.25)*size.height))
            context.stroke(path,with:.color(GameStyle.ink.opacity(0.8)),style:StrokeStyle(lineWidth:30,lineCap:.round))
            context.stroke(path,with:.color(StudioStyle.colors[0]),style:StrokeStyle(lineWidth:24,lineCap:.round))
            context.stroke(path,with:.color(.white.opacity(0.7)),style:StrokeStyle(lineWidth:3,lineCap:.round,dash:[4,12]))
        }
    }
}
