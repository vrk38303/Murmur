import XCTest
import SwiftData
@testable import Murmur

@MainActor
final class CallsListViewModelTests: XCTestCase {
    func testQueryFilters() throws {
        let container = MurmurStore.previewContainer()
        let services = ServiceContainer(modelContainer: container)
        let ctx = ModelContext(container)
        ctx.insert(CallEntity(title: "Neera Patel", contactName: "Neera Patel",
                              audioFileName: "1"))
        ctx.insert(CallEntity(title: "Mom", contactName: "Mom",
                              audioFileName: "2"))
        try ctx.save()

        let vm = CallsListViewModel(services: services)
        vm.load()
        XCTAssertEqual(vm.calls.count, 2)
        vm.query = "neera"
        vm.load()
        XCTAssertEqual(vm.calls.count, 1)
    }

    func testRelativeWhenBuckets() {
        let entity = CallEntity(title: "x",
                                startedAt: Date.now.addingTimeInterval(-3 * 3600),
                                audioFileName: "x")
        XCTAssertTrue(entity.relativeWhen.hasSuffix("h"))
    }
}
