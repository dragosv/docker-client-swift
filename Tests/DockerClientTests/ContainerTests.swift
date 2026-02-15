import Foundation
import Logging
import XCTest

@testable import DockerClientSwift

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

final class ContainerTests: XCTestCase {

    var client: DockerClient!

    override func setUp() {
        client = DockerClient.testable()
    }

    override func tearDown() async throws {
        try await client.shutdown()
    }

    func testCreateContainers() async throws {
        let image = try await client.images.pullImage(byName: "hello-world", tag: "latest")
        let container = try await client.containers.createContainer(image: image)

        XCTAssertEqual(container.command, "/hello")
    }

    func testListContainers() async throws {
        let image = try await client.images.pullImage(byName: "hello-world", tag: "latest")
        _ = try await client.containers.createContainer(image: image)

        let containers = try await client.containers.list(all: true)

        XCTAssert(containers.count >= 1)
    }

    func testInspectContainer() async throws {
        let image = try await client.images.pullImage(byName: "hello-world", tag: "latest")
        let container = try await client.containers.createContainer(image: image)

        let inspectedContainer = try await client.containers.get(
            containerByNameOrId: container.id.value)

        XCTAssertEqual(inspectedContainer.id, container.id)
        XCTAssertEqual(inspectedContainer.command, "/hello")
    }

    func testStartingContainerAndRetrievingLogs() async throws {
        let image = try await client.images.pullImage(byName: "hello-world", tag: "latest")
        let container = try await client.containers.createContainer(image: image)
        _ = try await container.start(on: client)
        let output = try await container.logs(on: client)
        // Depending on CPU architecture, step 2 of the log output may by:
        // 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
        //    (amd64)
        // or
        // 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
        //    (arm64v8)
        //
        // Just check the lines before and after this line
        let expectedOutputPrefix = """

            Hello from Docker!
            This message shows that your installation appears to be working correctly.

            To generate this message, Docker took the following steps:
             1. The Docker client contacted the Docker daemon.
             2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
            """
        let expectedOutputSuffix = """
             3. The Docker daemon created a new container from that image which runs the
                executable that produces the output you are currently reading.
             4. The Docker daemon streamed that output to the Docker client, which sent it
                to your terminal.

            To try something more ambitious, you can run an Ubuntu container with:
             $ docker run -it ubuntu bash

            Share images, automate workflows, and more with a free Docker ID:
             https://hub.docker.com/

            For more examples and ideas, visit:
             https://docs.docker.com/get-started/

            """

        XCTAssertTrue(
            output.hasPrefix(expectedOutputPrefix),
            """
            "\(output)"
            did not start with
            "\(expectedOutputPrefix)"
            """
        )
        XCTAssertTrue(
            output.hasSuffix(expectedOutputSuffix),
            """
            "\(output)"
            did not end with
            "\(expectedOutputSuffix)"
            """
        )
    }

    func testStartingContainerForwardingToSpecificPort() async throws {
        let image = try await client.images.pullImage(byName: "nginxdemos/hello", tag: "plain-text")
        let container = try await client.containers.createContainer(
            image: image, portBindings: [PortBinding(hostPort: 8080, containerPort: 80)])
        _ = try await container.start(on: client)

        let url = URL(string: "http://localhost:8080")!
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as? HTTPURLResponse
        XCTAssertEqual(httpResponse?.statusCode, 200)
        XCTAssertEqual(httpResponse?.value(forHTTPHeaderField: "Content-Type"), "text/plain")
        XCTAssertTrue(String(data: data, encoding: .utf8)!.hasPrefix("Server address"))

        try await container.stop(on: client)
    }

    func testStartingContainerForwardingToRandomPort() async throws {
        let image = try await client.images.pullImage(byName: "nginxdemos/hello", tag: "plain-text")
        let container = try await client.containers.createContainer(
            image: image, portBindings: [PortBinding(containerPort: 80)])
        let portBindings = try await container.start(on: client)
        let randomPort = portBindings[0].hostPort

        let url = URL(string: "http://localhost:\(randomPort)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        let httpResponse = response as? HTTPURLResponse
        XCTAssertEqual(httpResponse?.statusCode, 200)
        XCTAssertEqual(httpResponse?.value(forHTTPHeaderField: "Content-Type"), "text/plain")
        XCTAssertTrue(String(data: data, encoding: .utf8)!.hasPrefix("Server address"))

        try await container.stop(on: client)
    }

    func testPruneContainers() async throws {
        let image = try await client.images.pullImage(byName: "nginx", tag: "latest")
        let container = try await client.containers.createContainer(image: image)
        _ = try await container.start(on: client)
        try await container.stop(on: client)

        let pruned = try await client.containers.prune()

        let containers = try await client.containers.list(all: true)
        XCTAssert(!containers.map(\.id).contains(container.id))
        XCTAssert(pruned.reclaimedSpace > 0)
        XCTAssert(pruned.containersIds.contains(container.id))
    }
}
