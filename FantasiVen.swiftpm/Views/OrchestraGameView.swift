import SwiftUI

struct OrchestraGameView:View {
    @EnvironmentObject private var store:FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    let friend:FantasyFriend
    @State private var pattern=OrchestraPattern()
    @State private var playing=false
    @State private var recording=false
    @State private var editing=false
    @State private var beat = -1
    @State private var saved=false
    @State private var signals=[0,0,0]
    @State private var celebration=0
    @State private var preset=0
    private func performer(_ row:Int)->FantasyFriend {
        let others=store.friends.filter {$0.id != friend.id}
        return row == 0 ? friend : (others.indices.contains(row-1) ? others[row-1] : friend)
    }
    var body:some View {
        AdventureGameShell(kind:.orchestra) {active in
            GeometryReader {proxy in
                ZStack {
                    Ellipse().fill(Color.purple.opacity(0.6)).frame(width:proxy.size.width*1.2,height:proxy.size.height*0.3)
                        .position(x:proxy.size.width/2,y:proxy.size.height*0.65).allowsHitTesting(false)
                    HStack(alignment:.bottom,spacing:6) {
                        ForEach(0..<3) {row in
                            VStack(spacing:8) {
                                LivingFriend(friend:performer(row),action:row == 0 ? .jump : row == 1 ? .dance : .tickle,signal:signals[row],audible:false,onTouch:{strike(row)})
                                    .frame(height:proxy.size.height*0.37)
                                    .scaleEffect(reduced || signals[row].isMultiple(of:2) ? 1 : 1.04)
                                    .animation(reduced ? nil : .spring(response:0.3,dampingFraction:0.65),value:signals[row])
                                Button {strike(row)} label:{
                                    Text(["🥁","🎹","🎤"][row]).font(.system(size:proxy.size.width>600 ? 65 : 42))
                                        .frame(maxWidth:.infinity,minHeight:90)
                                        .background(RoundedRectangle(cornerRadius:28).fill(StudioStyle.colors[row]))
                                        .overlay(RoundedRectangle(cornerRadius:28).stroke(.white,lineWidth:3))
                                }.buttonStyle(SquishStyle()).accessibilityLabel(store.t("instrument_\(row)"))
                            }.frame(width:max(1,(proxy.size.width-32)/3))
                        }
                    }.padding(.horizontal,10).position(x:proxy.size.width/2,y:proxy.size.height*0.46)
                    if playing {
                        HStack(spacing:10) {
                            ForEach(0..<8) {column in
                                Circle().fill(column == beat ? Color.yellow : .white.opacity(0.35))
                                    .frame(width:column == beat ? 20 : 12,height:column == beat ? 20 : 12)
                            }
                        }.position(x:proxy.size.width/2,y:proxy.size.height*0.77).allowsHitTesting(false)
                    }
                    PlayCelebration(revision:celebration)
                    VStack {
                        Spacer()
                        if saved {Text(store.t("saved")).padding(10).background(Capsule().fill(.white))}
                        PlayDock {
                            PlayToken(symbol:playing ? "⏸️" : "▶️",label:store.t(playing ? "stopSong" : "playSong")) {playing.toggle()}
                            Spacer(minLength:0)
                            PlayToken(symbol:"🔴",label:store.t("recordMusic"),selected:recording) {
                                recording.toggle();if recording {pattern=OrchestraPattern();saved=false;beat = -1;playing=true}
                            }
                            PlayToken(symbol:"🎲",label:store.t("newBeat")) {preset+=1;seed();playing=true}
                            PlayToken(symbol:"🎼",label:store.t("editBeat")) {editing=true}
                            RoundButton(icon:"heart.fill",label:store.t("saveCreation"),action:save)
                        }
                    }
                }
            }
            .task(id:"\(active)-\(playing)-\(editing)") {
                SoundService.shared.setPerformance(active && playing && !editing)
                guard active && playing && !editing else {return}
                while !Task.isCancelled {
                    beat=(beat+1)%8
                    for row in 0..<3 where pattern.rows[row][beat] {
                        SoundService.shared.instrument(row,beat:beat,voice:performer(row).voice?.rawValue ?? 0);signals[row]+=1
                    }
                    do {try await Task.sleep(nanoseconds:UInt64([0.55,0.42,0.32][store.settings.challengeLevel-1]*1_000_000_000))}
                    catch {return}
                }
            }
        }.onAppear {if let song=friend.song {pattern=song} else {seed()}}
            .onDisappear {SoundService.shared.setPerformance(false)}
            .sheet(isPresented:$editing) {editor}
    }
    private func strike(_ row:Int) {
        SoundService.shared.instrument(row,beat:max(0,beat),voice:performer(row).voice?.rawValue ?? 0);signals[row]+=1;celebration+=1
        if recording {
            let column=max(0,beat)
            if !pattern.rows[row][column] {pattern.toggle(row:row,beat:column);saved=false}
        }
    }
    private func seed() {
        pattern=OrchestraPattern.preset(preset);saved=false
    }
    private func save() {
        guard var current=store.friends.first(where:{$0.id == friend.id}) else {return}
        current.song=pattern;saved=store.save(current)
    }
    private var editor:some View {
        ZStack {
            WorldBackdrop(world:.stars,animated:false)
            VStack(spacing:20) {
                Text(store.t("songHint")).font(.system(.title3,design:.rounded).weight(.bold)).foregroundColor(.white)
                ScrollView(.horizontal) {
                    VStack(spacing:12) {
                        ForEach(0..<3) {row in
                            HStack(spacing:8) {
                                ForEach(0..<8) {column in
                                    Button {pattern.toggle(row:row,beat:column);saved=false} label:{
                                        Text(pattern.rows[row][column] ? "♪" : "·")
                                            .font(.title2).frame(width:48,height:54)
                                            .background(RoundedRectangle(cornerRadius:14).fill(pattern.rows[row][column] ? StudioStyle.colors[row] : .white))
                                    }.buttonStyle(SquishStyle())
                                        .accessibilityLabel(store.t("instrument_\(row)")+", "+store.t("beat")+" \(column+1)")
                                        .accessibilityAddTraits(pattern.rows[row][column] ? .isSelected : [])
                                }
                            }
                        }
                    }.padding(8)
                }
                CandyButton(title:store.t("continue"),icon:"checkmark") {editing=false}
            }.padding(24).frame(maxWidth:600)
        }
    }
}
