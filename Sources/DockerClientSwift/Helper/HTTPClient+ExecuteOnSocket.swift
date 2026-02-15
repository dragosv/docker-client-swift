import AsyncHTTPClient
import Foundation
import Logging
import NIO
import NIOHTTP1

extension HTTPClient {
    /// Executes a HTTP request on a socket.
    /// - Parameters:
    ///   - method: HTTP method.
    ///   - socketPath: The path to the unix domain socket to connect to.
    ///   - urlPath: The URI path and query that will be sent to the server.
    ///   - body: Request body.
    ///   - deadline: Point in time by which the request must complete.
    ///   - logger: The logger to use for this request.
    ///   - headers: Custom HTTP headers.
    /// - Returns: Returns the `Response` of the request.
    public func execute(
        _ method: HTTPMethod = .GET, socketPath: String, urlPath: String, body: Body? = nil,
        deadline: NIODeadline? = nil, logger: Logger, headers: HTTPHeaders
    ) async throws -> Response {
        guard let url = URL(httpURLWithSocketPath: socketPath, uri: urlPath) else {
            throw HTTPClientError.invalidURL
        }
        let request = try Request(url: url, method: method, headers: headers, body: body)
        return try await self.execute(request: request, deadline: deadline, logger: logger).get()
    }
}
