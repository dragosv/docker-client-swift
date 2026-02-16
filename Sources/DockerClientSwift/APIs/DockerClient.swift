import AsyncHTTPClient
import Foundation
import Logging
import NIO
import NIOHTTP1

/// The entry point for docker client commands.
public class DockerClient {
    private let daemonSocket: String
    private let client: HTTPClient
    internal let logger: Logger

    /// Initialize the `DockerClient`.
    /// - Parameters:
    ///   - daemonSocket: The socket path where the Docker API is listening on. Default is `/var/run/docker.sock`.
    ///   - client: `HTTPClient` instance that is used to execute the requests.
    ///   - logger: `Logger` for the `DockerClient`. Default is `.init(label: "docker-client")`.
    public init(
        daemonSocket: String = "/var/run/docker.sock",
        client: HTTPClient = HTTPClient(eventLoopGroupProvider: .singleton),
        logger: Logger = .init(label: "docker-client")
    ) {
        self.daemonSocket = daemonSocket
        self.client = client
        self.logger = logger
    }

    /// Shuts down the client. The client needs to be shutdown otherwise it can crash on exit.
    public func syncShutdown() throws {
        try client.syncShutdown()
    }

    /// Shuts down the client asynchronously.
    public func shutdown() async throws {
        try await client.shutdown()
    }

    /// Executes a request to a specific endpoint.
    /// - Parameter endpoint: `Endpoint` instance with all necessary data and parameters.
    /// - Returns: Returns the expected result defined by the `Endpoint`.
    internal func run<T: Endpoint>(_ endpoint: T) async throws -> T.Response {
        logger.info("Execute Endpoint: \(endpoint.path)")
        let response = try await client.execute(
            endpoint.method, socketPath: daemonSocket, urlPath: "/v1.44/\(endpoint.path)",
            body: endpoint.body.map { HTTPClient.Body.data(try! $0.encode()) }, logger: logger,
            headers: HTTPHeaders([("Content-Type", "application/json"), ("Host", "localhost")]))
        response.logResponseBody(logger)
        return try response.decode(as: T.Response.self)
    }

    /// Executes a request to a specific pipeline endpoint.
    /// - Parameter endpoint: `PipelineEndpoint` instance with all necessary data and parameters.
    /// - Returns: Returns the expected result defined and transformed by the `PipelineEndpoint`.
    internal func run<T: PipelineEndpoint>(_ endpoint: T) async throws -> T.Response {
        logger.info("Execute PipelineEndpoint: \(endpoint.path)")
        let response = try await client.execute(
            endpoint.method, socketPath: daemonSocket, urlPath: "/v1.44/\(endpoint.path)",
            body: endpoint.body.map { HTTPClient.Body.data(try! $0.encode()) }, logger: logger,
            headers: HTTPHeaders([("Content-Type", "application/json"), ("Host", "localhost")]))
        response.logResponseBody(logger)
        return try response.mapString(map: endpoint.map(data:))
    }
}
