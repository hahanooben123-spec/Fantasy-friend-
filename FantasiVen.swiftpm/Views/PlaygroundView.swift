import SwiftUI

private enum PlayPicker: Int, Identifiable {
    case worlds, friends
    var id: Int { rawValue }
}

struct PlaygroundView: View {
    @EnvironmentObject private var store: FriendStore
    var initialID: UUID? = nil
    var onCreate: () -> Void
    @State private var selectedID: UUID?
    @State private var action: PlayAction = .jump
    @State private var signal = 0
    @State private var picker: PlayPicker?
    private let toys: [ToyKind] = [.feather, .berry, .jump, .music, .moon, .heart]
    private var friend: FantasyFriend? {
        store.friends.first { $0.id == (selectedID ?? initialID) } ?? store.friends.first
    }

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 700
            ZStack {
                WorldBackdrop(world: friend?.world ?? .forest)
                VStack(spacing: 8) {
                    AdventureHeading(title: store.t("playRoom"), subtitle: store.t("ragdollHint"))
                    if let friend = friend {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 18) {
                                if wide {
                                    HStack(spacing: 20) {
                                        RagdollPlayground(friend: friend, action: action, signal: signal)
                                            .id(friend.id).frame(height: min(geometry.size.height * 0.68, 610))
                                        actionGrid.frame(width: 245)
                                    }
                                } else {
                                    RagdollPlayground(friend: friend, action: action, signal: signal)
                                        .id(friend.id).frame(height: min(geometry.size.height * 0.46, 405))
                                    actionGrid
                                }
                                HStack(spacing: 12) {
                                    Button { picker = .friends } label: {
                                        HStack(spacing: 6) {
                                            CharacterView(friend: friend).frame(width: 49, height: 54)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(store.t("chooseFriend")).font(.system(size: 10, weight: .bold, design: .rounded))
                                                Text(friend.name).font(.system(.subheadline, design: .rounded).weight(.heavy)).lineLimit(1)
                                            }
                                            Spacer(minLength: 0)
                                            Image(systemName: "chevron.down").font(.system(size: 12, weight: .heavy))
                                        }.padding(.horizontal, 10).frame(maxWidth: .infinity).frame(height: 66)
                                            .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.85)))
                                    }
                                    Button { picker = .worlds } label: {
                                        HStack(spacing: 8) {
                                            WorldBackdrop(world: friend.world, immersive: false, animated: false).frame(width: 48, height: 44).clipShape(RoundedRectangle(cornerRadius: 13))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(store.t("chooseWorld")).font(.system(size: 10, weight: .bold, design: .rounded))
                                                Text(store.t(Words.worldKeys[friend.world.rawValue])).font(.system(.subheadline, design: .rounded).weight(.heavy)).lineLimit(1).minimumScaleFactor(0.7)
                                            }
                                            Spacer(minLength: 0)
                                            Image(systemName: "chevron.down").font(.system(size: 12, weight: .heavy))
                                        }.padding(.horizontal, 10).frame(maxWidth: .infinity).frame(height: 66)
                                            .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.85)))
                                    }
                                }.buttonStyle(SquishStyle())
                            }.padding(.horizontal, 18).padding(.bottom, 24).frame(maxWidth: 1120).frame(maxWidth: .infinity)
                        }
                    } else { EmptyCollectionView(create: onCreate) }
                }
            }
        }.foregroundColor(GameStyle.ink).navigationBarHidden(true)
        .sheet(item: $picker) { choice in pickerContent(choice) }
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
            ForEach(Array(PlayAction.allCases.enumerated()), id: \.element.rawValue) { index, item in
                Button { action = item; signal += 1 } label: {
                    VStack(spacing: 3) {
                        ToyGlyph(kind: toys[index]).frame(width: 53, height: 53)
                        Text(store.t(item.rawValue)).font(.system(.subheadline, design: .rounded).weight(.heavy))
                    }.foregroundColor(GameStyle.ink).frame(maxWidth: .infinity).frame(height: 96)
                        .background(RoundedRectangle(cornerRadius: 28).fill(StudioStyle.colors[index]))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.85), lineWidth: 2))
                        .shadow(color: StudioStyle.colors[index].opacity(0.4), radius: 0, y: 5)
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? -2 : 2))
                }.buttonStyle(SquishStyle())
            }
        }
    }

    private func pickerContent(_ choice: PlayPicker) -> some View {
        ZStack {
            WorldBackdrop(world: .clouds)
            VStack(spacing: 12) {
                HStack {
                    Text(store.t(choice == .worlds ? "chooseWorld" : "chooseFriend")).font(.system(.title2, design: .rounded).weight(.heavy))
                    Spacer()
                    RoundButton(icon: "xmark", label: store.t("close")) { picker = nil }
                }.padding(20)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 15)], spacing: 18) {
                        if choice == .worlds {
                            ForEach(World.allCases, id: \.rawValue) { world in
                                Button {
                                    guard var value = friend else { return }
                                    value.world = world
                                    if store.save(value) { picker = nil; SoundService.shared.play(.click) }
                                } label: {
                                    VStack(spacing: 9) {
                                        WorldBackdrop(world: world, immersive: false, animated: false).frame(height: 112).clipShape(RoundedRectangle(cornerRadius: 24))
                                        Text(store.t(Words.worldKeys[world.rawValue])).font(.system(.headline, design: .rounded)).padding(.bottom, 10)
                                    }.padding(8).background(RoundedRectangle(cornerRadius: 30).fill(.white.opacity(0.85)))
                                        .overlay(RoundedRectangle(cornerRadius: 30).stroke(friend?.world == world ? GameStyle.purple : .white, lineWidth: 3))
                                }.buttonStyle(SquishStyle()).accessibilityAddTraits(friend?.world == world ? .isSelected : [])
                            }
                        } else {
                            ForEach(store.friends) { value in
                                Button { selectedID = value.id; signal = 0; picker = nil } label: { FriendHomeCard(friend: value) }
                                    .buttonStyle(SquishStyle()).accessibilityAddTraits(friend?.id == value.id ? .isSelected : [])
                            }
                        }
                    }.padding(20)
                }
            }
        }.foregroundColor(GameStyle.ink)
    }
}
