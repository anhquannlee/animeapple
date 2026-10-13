// LoadingView.swift
// AnimeVsubIOS
//
// Skeleton shimmer loading placeholders used while home page data is fetching.
// Uses a phase-based animation that slides a highlight gradient across each
// placeholder rectangle — no third-party libraries required.

import SwiftUI

// MARK: - Shimmer Modifier

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let width = geo.size.width
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(0.08), location: 0.5),
                            .init(color: Color.white.opacity(0), location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 2)
                    .offset(x: phase * width)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.4).repeatForever(autoreverses: false)
                ) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    /// Applies an animated shimmer overlay — call on any gray placeholder rectangle.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - SkeletonRect

/// A single gray shimmer rectangle with configurable dimensions.
struct SkeletonRect: View {
    var width: CGFloat? = nil   // nil → fill available width
    var height: CGFloat
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(white: 0.20))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - AnimeCardSkeleton

/// Skeleton placeholder that mirrors an `AnimeCardView` (medium size).
struct AnimeCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Poster image placeholder
            SkeletonRect(height: 145, cornerRadius: 10)
                .frame(width: 100)

            // Name line 1
            SkeletonRect(width: 90, height: 10)
            // Name line 2
            SkeletonRect(width: 60, height: 10)
        }
        .frame(width: 100)
    }
}

// MARK: - CarouselSkeleton

private struct CarouselSkeleton: View {
    var body: some View {
        SkeletonRect(height: 220, cornerRadius: 0)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - HorizontalListSkeleton

private struct HorizontalListSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    AnimeCardSkeleton()
                }
            }
            .padding(.horizontal, 16)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - SectionHeaderSkeleton

private struct SectionHeaderSkeleton: View {
    var body: some View {
        HStack {
            SkeletonRect(width: 140, height: 14)
            Spacer()
            SkeletonRect(width: 60, height: 12)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - GridSkeleton

private struct GridSkeleton: View {
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonRect(height: 145, cornerRadius: 10)
                    SkeletonRect(height: 10)
                    SkeletonRect(width: 60, height: 10)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - QuickLinksSkeleton

private struct QuickLinksSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonRect(height: 56, cornerRadius: 12)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - HomeLoadingView (public)

/// Full-page skeleton that mirrors the HomeScreen layout while data is loading.
struct HomeLoadingView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Carousel placeholder
                CarouselSkeleton()

                // Quick links row
                QuickLinksSkeleton()

                // This Season section
                SectionHeaderSkeleton()
                HorizontalListSkeleton()

                // Nominate section (grid)
                SectionHeaderSkeleton()
                GridSkeleton()

                // Hot Update section
                SectionHeaderSkeleton()
                HorizontalListSkeleton()

                // Pre-release section
                SectionHeaderSkeleton()
                HorizontalListSkeleton()

                // Last Update section (grid)
                SectionHeaderSkeleton()
                GridSkeleton()

                Spacer(minLength: 80)
            }
            .padding(.vertical, 0)
        }
        .background(Color(hex: "#1a1a1a"))
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#if DEBUG
struct HomeLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        HomeLoadingView()
            .preferredColorScheme(.dark)
    }
}
#endif
