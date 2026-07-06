import Vapor
import PulseServer

let app = try await Application.make(try Environment.detect())
do {
    try configure(app)
    try await app.execute()
} catch {
    app.logger.report(error: error)
}
try await app.asyncShutdown()
