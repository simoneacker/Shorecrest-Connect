//
//  MapTableViewCell.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 3/29/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import MapKit // For map functionality

/// Custom cell used to display specific coordinates on a map with a labeled pin.
class MapTableViewCell: UITableViewCell {

  /// Outlet to the address label which will display the location name and address.
  @IBOutlet weak var addressLabel: UILabel!
  
  /// Outlet to the map view for displaying a given location.
  @IBOutlet weak var mapView: MKMapView!
  
  /// Delegate which allows the cell to notify the controller of user interaction within the cell.
  var delegate: MapTableViewCellDelegate?
  
  /**
      Sets the text in the addressLabel to the passed address.
   
      - Parameters:
          - address: The street address of the location.
   */
  public func displayLocation(address: String) {
    addressLabel.text = address
  }
  
  /**
      Sets the region shown on the map and puts a labeled pin on the exact location.
   
      - Parameters:
          - latitude: The latitude to be displayed as a decimal (between -90.0 and 90.0).
          - longitude: The longitude to be displayed as a decimal (between -180.0 and 180.0).
   */
  public func displayLocation(latitude: Double, longitude: Double) {
    mapView.delegate = self // Set before it is used to load overlays and annotations
    
    // Make a location from the passed in lat/long
    let location = CLLocation(latitude: latitude, longitude: longitude)
    
    // Sets region shown on map
    let locationRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500) //500 meters vertical/horizontal area shown
    mapView.setRegion(locationRegion, animated: false)
    
    // Draw circle around location pin (check in area)
    let locationCircle = MKCircle(center: location.coordinate, radius: 200) //200 meters
    mapView.add(locationCircle)
    
    // Set pin for location
    let locationPin = MKPointAnnotation()
    locationPin.coordinate = location.coordinate
    mapView.addAnnotation(locationPin)
  }
  
  /// Called when the user taps the directions button.
  @IBAction func didTapGetDirections(_ sender: UIButton) {
    delegate?.didTapGetDirections()
  }
}

/// Adds MKMapViewDelegate functionality to the custom cell so the map view can render overlays and annotations.
extension MapTableViewCell: MKMapViewDelegate {
  
  /// Used to render circlular shadow overlay for the loaded location pin.
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if overlay is MKCircle {
      let circleRenderer = MKCircleRenderer(overlay: overlay)
      circleRenderer.strokeColor = UIColor.gray
      circleRenderer.fillColor = UIColor.gray.withAlphaComponent(0.2)
      circleRenderer.lineWidth = 1.0
      return circleRenderer
    } else {
      return MKPolylineRenderer() //default renderer
    }
  }
  
  /// Used to color the pin for the displayed location.
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if annotation is MKPointAnnotation {
      let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
      pinAnnotationView.pinTintColor = UIColor.black
      return pinAnnotationView
    }
    
    return nil //nil so annotations like user location can default views
  }
}

/// Delegate for the `MapTableViewCell` to tell its controller of any user interaction within it.
protocol MapTableViewCellDelegate {
  
  /**
      Tells the delegate that the user tapped the get directions button.
   */
  func didTapGetDirections()
}
