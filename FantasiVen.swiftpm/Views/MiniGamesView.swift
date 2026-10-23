import SwiftUI

struct MiniGamesView: View {
    @EnvironmentObject private var store: FriendStore
    let onCreate: () -> Void
    @State private var selectedID: UUID?
    @State private var choosingFriend = false
    private var friend: FantasyFriend? {
        store.friends.first { $0.id == selectedID } ?? store.friends.first
    }

    var body: some View {
        ZStack {
            WorldBackdrop(world: .rainbow)
            VStack(spacing: 12) {
                AdventureHeading(title: store.t("miniGames"), subtitle: store.t("miniGamesHint"))
                if let friend = friend {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            Button { choosingFriend = true } label: {
                                HStack(spacing: 12) {
                                    CharacterView(friend: friend).frame(width: 92, height: 98)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(store.t("chooseFriend")).font(.system(.caption, design: .rounded).weight(.bold))
                                        Text(friend.name).font(.system(.title2, design: .rounded).weight(.heavy))
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.triangle.2.circlepath").font(.title2)
                                }.padding(.horizontal, 18).padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 30).fill(.white.opacity(0.9)))
                            }.buttonStyle(SquishStyle())
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 450))], spacing: 20) {
                            ForEach(MiniGameKind.menuGames) { kind in
                                NavigationLink(destination: GameDestinationView(kind: kind, friend: friend).id(friend.id)) {
                                    HStack(spacing: 14) {
                                        MiniGameArt(kind: kind)
                                        VStack(alignment: .leading, spacing: 7) {
                                            Text(store.t(kind.titleKey)).font(.system(.title2, design: .rounded).weight(.heavy))
                                            Text(store.t(kind.hintKey)).font(.system(.subheadline, design: .rounded)).fixedSize(horizontal: false, vertical: true)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "play.fill").font(.title2)
                                    }.padding(16).foregroundColor(GameStyle.ink)
                                        .frame(maxWidth: .infinity, minHeight: 145)
                                        .background(CandySurface(color: kind.tint, cornerRadius: 34))
                                        .contentShape(RoundedRectangle(cornerRadius: 34))
                                }.buttonStyle(SquishStyle())
                            }
                            }
                            Text(store.t("gamesGentle")).font(.system(.caption, design: .rounded).weight(.semibold)).multilineTextAlignment(.center)
                        }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
                    }
                } else { EmptyCollectionView(create: onCreate) }
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true)
            .sheet(isPresented: $choosingFriend) {
                ZStack {
                    WorldBackdrop(world: .clouds)
                    VStack {
                        HStack {
                            Text(store.t("chooseFriend")).font(.system(.title2, design: .rounded).weight(.heavy))
                            Spacer()
                            RoundButton(icon: "xmark", label: store.t("close")) { choosingFriend = false }
                        }.padding(20)
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], spacing: 18) {
                                ForEach(store.friends) { candidate in
                                    Button {
                                        selectedID = candidate.id
                                        choosingFriend = false
                                        SoundService.shared.play(.click)
                                    } label: { FriendHomeCard(friend: candidate) }
                                        .buttonStyle(SquishStyle())
                                        .accessibilityAddTraits(friend?.id == candidate.id ? .isSelected : [])
                                }
                            }.padding(20)
                        }
                    }
                }.foregroundColor(GameStyle.ink)
            }
    }
}

extension MiniGameKind {
    var tint: Color {
        switch self {
        case .slide, .trampoline, .apples: return Color(red: 1, green: 0.70, blue: 0.15)
        case .orchestra, .path, .bubbles: return Color(red: 0.22, green: 0.77, blue: 1)
        case .kitchen, .hide: return Color(red: 0.64, green: 0.87, blue: 0.22)
        }
    }
}

struct MiniGamesDoor: View {
    @EnvironmentObject private var store: FriendStore
    var body: some View {
        HStack(spacing: 10) {
            MiniGameArt(kind: .apples).scaleEffect(0.76).frame(width: 80, height: 85)
            VStack(alignment: .leading, spacing: 5) {
                Text(store.t("miniGames")).font(.system(size: 24, weight: .heavy, design: .rounded))
                Text(store.t("miniGamesDoor")).font(.system(.subheadline, design: .rounded))
            }
            Spacer(minLength: 0)
            Image(systemName: "play.fill").font(.title2).padding(.trailing, 19)
        }.foregroundColor(GameStyle.ink).padding(9).frame(maxWidth: .infinity)
            .background(CandySurface(color: Color(red: 0.49, green: 0.76, blue: 1), cornerRadius: 30))
            .contentShape(RoundedRectangle(cornerRadius: 30))
    }
}
