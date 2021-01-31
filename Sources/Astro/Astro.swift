import Foundation
import CoreLocation

extension Date {
  var julianDay: Double {
    let interval = self.timeIntervalSince1970
    return ((interval / 86400.0) + 2440587.5)
  }
  
  init(julianDay: Double) {
    let unixTime = (julianDay - 2440587) * 86400.0
    self.init(timeIntervalSince1970: unixTime)
  }
}

extension FloatingPoint {
  var deg2rad: Self {
    self * .pi / 180
  }
  var rad2deg: Self {
    self / .pi * 180
  }
}

public extension Date {
  var sunDeclinationRightAscencionRadian: (Double, Double) {
    // these come in handy
    let twopi = Double.pi * 2
    
    // the Astronomer's Almanac method used here is based on Epoch 2000, so we need to
    // convert the date into that format. We start by calculating "n", the number of
    // days since 1 January 2000. So if your date format is 1970-based, convert that
    // a pure julian date and pass that in. If your date is 2000-based, then
    // just let n = date
    let n = self.julianDay - 2451545.0
    
    // it continues by calculating the position in ecliptic coordinates,
    // starting with the mean longitude of the sun in degrees, corrected for aberation
    var meanLongitudeDegrees = 280.460 + (0.9856474 * n)
    meanLongitudeDegrees = meanLongitudeDegrees.truncatingRemainder(dividingBy: 360.0)
    
    // and the mean anomaly in degrees
    var meananomaly_degrees = 357.528 + (0.9856003 * n)
    meananomaly_degrees = meananomaly_degrees.truncatingRemainder(dividingBy: 360.0)
    let meanAnomalyRadians = meananomaly_degrees.deg2rad
    
    // and finally, the eliptic longitude in degrees
    var elipticLongitudeDegrees = meanLongitudeDegrees + (1.915 * sin(meanAnomalyRadians)) + (0.020 * sin(2 * meanAnomalyRadians))
    elipticLongitudeDegrees = elipticLongitudeDegrees.truncatingRemainder(dividingBy: 360.0)
    let elipticLongitudeRadians = elipticLongitudeDegrees.deg2rad
    
    // now we want to convert that to equatorial coordinates
    let obliquityDegrees = 23.439 - (0.0000004 * n)
    let obliquityRadians = obliquityDegrees.deg2rad
    
    // right ascention in radians
    let num = cos(obliquityRadians) * sin(elipticLongitudeRadians)
    let den = cos(elipticLongitudeRadians)
    var rightAscensionRadians = atan(num / den)
    rightAscensionRadians = rightAscensionRadians.truncatingRemainder(dividingBy: Double.pi)
    if den < 0 {
      rightAscensionRadians = rightAscensionRadians + Double.pi
    } else if num < 0 {
      rightAscensionRadians = rightAscensionRadians + twopi
    }
    // declination is simpler...
    let declinationRadians = asin(sin(obliquityRadians) * sin(elipticLongitudeRadians))
    
    return (declinationRadians, rightAscensionRadians)
  }
  
  var sunDeclinationRightAscencion: (Double, Double) {
    let radian = self.sunDeclinationRightAscencionRadian
    return (radian.0.rad2deg, radian.1.rad2deg)
  }
  
  func sunPosition(lat: Double, lon: Double) -> (altitude: Double, azimuth: Double) {
    Astro.sunPosition(date: self, lat: lat, lon: lon)
  }
  
  func sunPosition(at location: CLLocationCoordinate2D) -> (altitude: Double, azimuth: Double) {
    Astro.sunPosition(date: self, lat: location.latitude, lon: location.longitude)
  }
  
  var sunLocation: CLLocationCoordinate2D {
    var (elevation, azimuth) = sunPosition(at: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    elevation = elevation.deg2rad
    azimuth = azimuth.deg2rad
    let longitude = atan2(sin(azimuth), tan(elevation))
    let latitude = asin(cos(azimuth) * cos(elevation))
    
    return CLLocationCoordinate2D(latitude: latitude.rad2deg, longitude: longitude.rad2deg)
  }
}

func sunPosition(date: Date, lat: Double, lon: Double) -> (altitude: Double, azimuth: Double) {
  // these come in handy
  let n = date.julianDay - 2451545.0
  
  // latitude to radians
  let lat_radians = lat.deg2rad
  
  let (dec_radians, rightAscensionRadians) = date.sunDeclinationRightAscencionRadian
  
  // and from there, to local coordinates
  // start with the UTZ sidereal time, which is probably a lot easier in non-Swift languages
  var utzCal = Calendar(identifier: .gregorian)
  utzCal.timeZone = TimeZone(secondsFromGMT: 0)!
  let h = Double(utzCal.component(.hour, from: date))
  let m = Double(utzCal.component(.minute, from: date))
  let f: Double // universal time in hours and decimals (not days!)
  if h == 0 && m == 0 {
    f = 0.0
  } else if h == 0 {
    f = m / 60.0
  } else if m == 0 {
    f = h
  } else {
    f = h + (m / 60.0)
  }
  var utz_sidereal_time = 6.697375 + 0.0657098242 * n + f
  utz_sidereal_time = utz_sidereal_time.truncatingRemainder(dividingBy: 24.0)
  
  // then convert that to local sidereal time
  var localtime = utz_sidereal_time + lon / 15.0
  localtime = localtime.truncatingRemainder(dividingBy: 24.0)
  let localtime_radians = localtime * 15.0 .deg2rad
  
  // hour angle in radians
  var hourangle_radians =  localtime_radians - rightAscensionRadians
  hourangle_radians = hourangle_radians.truncatingRemainder(dividingBy: .pi * 2)
  
  // get elevation in degrees
  let elevation_radians = (asin(sin(dec_radians) * sin(lat_radians) + cos(dec_radians) * cos(lat_radians) * cos(hourangle_radians)))
  let elevation_degrees = elevation_radians.rad2deg
  
  // and azimuth
  let azimuth_radians = asin( -cos(dec_radians) * sin(hourangle_radians) / cos(elevation_radians))
  
  // now clamp the output
  let azimuth_degrees: Double
  if (sin(dec_radians) - sin(elevation_radians) * sin(lat_radians) < 0) {
    azimuth_degrees = (Double.pi - azimuth_radians).rad2deg
  } else if (sin(azimuth_radians) < 0) {
    azimuth_degrees = (azimuth_radians + .pi * 2).rad2deg
  } else {
    azimuth_degrees = azimuth_radians.rad2deg
  }
  
  // all done!
  return (elevation_degrees, azimuth_degrees)
}
