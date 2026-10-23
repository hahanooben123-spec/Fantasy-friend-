import SwiftUI

/// A short, skippable passage through the actual destination's door.
struct VillageJourney: View {
    @EnvironmentObject private var store: FriendStore
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(\.scenePhase) private var phase
    let place: VillagePlace
    let friend: FantasyFriend
    let arrive: () -> Void
    @State private var open=false
    @State private var closeUp=false
    @State private var finished=false
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors:[StorybookStyle.teal,GameStyle.mixed(place.color,with:StorybookStyle.cream,amount:0.6)],
                    startPoint:.top,endPoint:.bottom).ignoresSafeArea()
                StorybookAtmosphere(lamps:true)
                VStack(spacing:14) {
                    Text(store.t(place.titleKey)).font(.system(size:29,weight:.heavy,design:.rounded))
                        .foregroundColor(StorybookStyle.cream).multilineTextAlignment(.center)
                    ZStack(alignment:.bottom) {
                        VillageBuilding(place:place,opening:open ? 1 : 0)
                            .scaleEffect(closeUp && !reduced ? 1.25 : 1,anchor:.bottom)
                        LivingFriend(friend:friend,audible:false,locomotion:open ? 0.8 : 0,active:phase == .active)
                            .frame(width:110,height:118)
                            .offset(x:open ? 0 : -65,y:open ? -5 : 15)
                            .scaleEffect(open && !reduced ? 0.70 : 1,anchor:.bottom)
                            .opacity(closeUp && !reduced ? 0 : 1)
                    }.frame(width:min(440,proxy.size.width*0.88))
                }.frame(maxWidth:.infinity,maxHeight:.infinity)
                VStack {Spacer();Text(store.t("villageEnter")).font(.system(size:15,weight:.bold,design:.rounded))
                    .foregroundColor(StorybookStyle.cream).padding(20)}
            }.contentShape(Rectangle()).onTapGesture(perform:finish)
                .accessibilityElement(children:.ignore)
                .accessibilityLabel(store.t(place.titleKey))
                .accessibilityHint(store.t("villageEnter"))
                .accessibilityAddTraits(.isButton).accessibilityAction(perform:finish)
        }.task(id:phase) {
            guard phase == .active,!finished else {return}
            SoundService.shared.play(.click)
            if reduced {finish();return}
            do {
                withAnimation(.easeInOut(duration:0.24)) {open=true}
                try await Task.sleep(nanoseconds:250_000_000)
                withAnimation(.easeIn(duration:0.24)) {closeUp=true}
                try await Task.sleep(nanoseconds:270_000_000)
                finish()
            } catch {return}
        }
    }
    private func finish() {
        guard !finished else {return}
        finished=true;arrive()
    }
}

struct VillageCompanionPicker: View {
    @EnvironmentObject private var store: FriendStore
    let create: () -> Void
    let close: () -> Void
    var body: some View {
        ZStack {
            WelcomeGardenBackdrop()
            VStack(spacing:16) {
                HStack {
                    Text(store.t("villageChooseCompanion")).font(.system(.title2,design:.rounded).weight(.heavy))
                    Spacer()
                    RoundButton(icon:"xmark",label:store.t("close"),action:close)
                }.padding(.horizontal,20).padding(.top,20)
                ScrollView {
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:145))],spacing:18) {
                        ForEach(store.friends) { friend in
                            Button {
                                store.selectCompanion(friend.id);SoundService.shared.play(.reaction);close()
                            } label: {
                                FriendHomeCard(friend:friend)
                                    .overlay(RoundedRectangle(cornerRadius:38)
                                        .stroke(store.companion.id == friend.id ? StorybookStyle.honey : .clear,lineWidth:4))
                            }.buttonStyle(SquishStyle())
                                .accessibilityAddTraits(store.companion.id == friend.id ? .isSelected : [])
                        }
                    }.padding(20).frame(maxWidth:850).frame(maxWidth:.infinity)
                }
                CandyButton(title:store.t("create"),icon:"paintbrush.fill",color:StorybookStyle.teal) {
                    close();create()
                }.padding(20).frame(maxWidth:500)
            }
        }.foregroundColor(GameStyle.ink)
    }
}
