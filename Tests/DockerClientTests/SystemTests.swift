import Logging
import XCTest

@testable import DockerClientSwift

final class SystemTests: XCTestCase {
    var client: DockerClient!

    override func setUp() {
        client = DockerClient.testable()
    }

    override func tearDown() async throws {
        try await client.shutdown()
    }

    func testDockerVersion() async throws {
        let _ = try await client.version()
    }
}
