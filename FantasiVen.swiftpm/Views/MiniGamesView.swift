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
                            ForEach(MiniGameKind.allCases) { kind in
                                NavigationLink(destination: MiniGameSessionView(kind: kind, friend: friend).id(friend.id)) {
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
                                        .background(RoundedRectangle(cornerRadius: 34).fill(kind.tint))
                                        .overlay(RoundedRectangle(cornerRadius: 34).stroke(.white.opacity(0.9), lineWidth: 3))
                                        .shadow(color: kind.tint.opacity(0.5), radius: 0, y: 6)
                                }.buttonStyle(SquishStyle())
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
        case .apples: return Color(red: 1, green: 0.82, blue: 0.59)
        case .bubbles: return Color(red: 0.68, green: 0.88, blue: 1)
        case .hide: return Color(red: 0.75, green: 0.91, blue: 0.65)
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
            .background(RoundedRectangle(cornerRadius: 30).fill(LinearGradient(colors: [.init(red: 0.79, green: 0.86, blue: 1), .init(red: 0.97, green: 0.76, blue: 0.89)], startPoint: .leading, endPoint: .trailing)))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white, lineWidth: 3))
            .shadow(color: GameStyle.purple.opacity(0.2), radius: 0, y: 5)
    }
}
