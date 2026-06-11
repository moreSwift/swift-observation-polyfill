import ObservationPolyfill
//import XCTest

//final class ModifyAccessorTests: XCTestCase {
//  func testCopyOnWrite() {
//    let object = CowObject()
//    let startId = object.container.id
//    XCTAssertEqual(object.container.id, startId)
//    object.container.mutate()
//    XCTAssertEqual(object.container.id, startId)
//  }
//}
//
private struct CowContainer {
  final class Contents {}
  var contents = Contents()
  mutating func mutate() {
    if !isKnownUniquelyReferenced(&contents) {
      contents = Contents()
    }
  }
  var id: ObjectIdentifier {
    ObjectIdentifier(contents)
  }
}

@ObservationPolyfill.Observable
private final class CowObject {
  var container = CowContainer()
}
