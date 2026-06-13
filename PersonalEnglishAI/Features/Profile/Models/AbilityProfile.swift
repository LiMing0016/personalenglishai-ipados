import Foundation

struct AbilityProfile: Decodable, Hashable {
    let grammarScore: Double?
    let vocabularyScore: Double?
    let coherenceScore: Double?

    static let preview = AbilityProfile(
        grammarScore: 6.5,
        vocabularyScore: 7.0,
        coherenceScore: 6.0
    )
}
