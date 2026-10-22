import SwiftUI

struct CreatorPersonalitySheet: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.presentationMode) private var presentation
    @Binding var friend: FantasyFriend
    @State private var signal = 0
    var body: some View {
        ZStack {
            WorkshopLook.cream.ignoresSafeArea()
            VStack(spacing:20) {
                HStack {
                    Text(store.t("personality")).font(.system(.title2,design:.rounded).weight(.heavy))
                    Spacer()
                    CreatorToolButton(mark:.done,label:store.t("continue"),tint:WorkshopLook.yellow) { presentation.wrappedValue.dismiss() }
                }
                LivingFriend(friend:friend,action:.dance,signal:signal).frame(maxHeight:290)
                HStack(spacing:12) {
                    ForEach(VoiceKind.allCases,id:\.rawValue) { voice in
                        Button {
                            friend.voice=voice;signal+=1
                            SoundService.shared.react(voice:voice.rawValue)
                        } label: {
                            Text(store.t("voice_\(voice.rawValue)"))
                                .font(.system(.body,design:.rounded).weight(.bold))
                                .frame(maxWidth:.infinity,minHeight:60)
                                .background(RoundedRectangle(cornerRadius:20).fill((friend.voice ?? .bell) == voice ? WorkshopLook.yellow : .white))
                        }.buttonStyle(SquishStyle())
                    }
                }
                HStack(spacing:12) {
                    ForEach(GaitKind.allCases,id:\.rawValue) { gait in
                        Button { friend.gait=gait;signal+=1 } label: {
                            Text(store.t("gait_\(gait.rawValue)"))
                                .font(.system(.body,design:.rounded).weight(.bold))
                                .frame(maxWidth:.infinity,minHeight:60)
                                .background(RoundedRectangle(cornerRadius:20).fill((friend.gait ?? .bounce) == gait ? WorkshopLook.yellow : .white))
                        }.buttonStyle(SquishStyle())
                    }
                }
                Spacer(minLength:0)
            }.padding(22).frame(maxWidth:600).foregroundColor(WorkshopLook.sea)
        }
    }
}
