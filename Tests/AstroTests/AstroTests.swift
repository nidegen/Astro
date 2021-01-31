import XCTest
@testable import Astro

import CoreLocation

final class AstroTests: XCTestCase {
  func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct
    // results.
    
    let autumnEquinox2020 = Date(timeIntervalSince1970: 1600781460)
    let winterSolstice2020 = Date(timeIntervalSince1970: 1608544980)
    let summerSolstice2020 = Date(timeIntervalSince1970: 1592689380)
    let vernalEquinox2020 = Date(timeIntervalSince1970: 1584676200)
    
    print(vernalEquinox2020.sunPosition(at: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
    print(summerSolstice2020.sunPosition(at: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
    print(autumnEquinox2020.sunPosition(at: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
    print(winterSolstice2020.sunPosition(at: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
    
    print(vernalEquinox2020.sunLocation)
    print(summerSolstice2020.sunLocation)
    print(autumnEquinox2020.sunLocation)
    print(winterSolstice2020.sunLocation)
    print(Date().sunLocation)
    print(Date().sunPosition(at: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
    
    XCTAssertEqual(vernalEquinox2020.sunLocation.latitude, 0, accuracy: 0.01)
    XCTAssertEqual(autumnEquinox2020.sunLocation.latitude, 0, accuracy: 0.01)
    XCTAssertEqual(summerSolstice2020.sunLocation.latitude, 23.43655, accuracy: 0.01)
    XCTAssertEqual(winterSolstice2020.sunLocation.latitude, -23.43655, accuracy: 0.01)
  }
  
  static var allTests = [
    ("testExample", testExample),
  ]
}
