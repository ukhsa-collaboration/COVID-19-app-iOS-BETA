
import ArgumentParser

public func run() -> Never {
    ReportCommand.main()
}

struct ReportCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "report",
        abstract: "A tool for producing reports from iOS app bundles.",
        subcommands: [
            ArchiveReportCommand.self,
            IPAReportCommand.self,
        ]
    )
    
    func run() throws {
        print("running")
    }
}
