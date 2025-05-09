@testable import Cactus
import Testing

@Test
func example() async throws {
    let int = Int.random(in: 10...100)
    #expect(int > 9)
    #expect(int < 101)
}
