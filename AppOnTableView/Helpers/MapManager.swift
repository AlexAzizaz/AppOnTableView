//
//  MapManager.swift
//  AppOnTableView
//
//  Created by onyx on 01.03.2020.
//  Copyright © 2020 Alex Al. All rights reserved.
//

import UIKit
import MapKit

class MapManager {
    
    let locationManager = CLLocationManager()
    
    var placeCoordinate: CLLocationCoordinate2D?
    var directionsArray: [MKDirections] = []
    let regionInMeters = 1000.00
    weak var mapVC: MapViewController?
    
    init(mapVC: MapViewController) {
        self.mapVC = mapVC
    }
    
    // Маркер Заведения
    func setupPlaceMark (place: Place, mapView: MKMapView) {
        
        guard let location = place.location else { return }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placemarkLocation.coordinate
            
            self.placeCoordinate = placemarkLocation.coordinate
            
            mapView.showAnnotations([annotation], animated: true)
            mapView.selectAnnotation(annotation, animated: true)
        }
        
    }
    
    // Проверка доступности сервисов
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () ->()) {
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAutorization(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlertController(title: "Error", message: "Location services are disabled on the device.")
            }
        }
    }
    
    // Проверка авторизации приложения для использования сервисов геолокации
    func checkLocationAutorization(mapView: MKMapView, segueIdentifier: String) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }
            break
        case .denied:
            showAlertController(title: "Error", message: "The user denied the use of location services for the app or they are disabled globally in Settings.")
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            showAlertController(title: "Error", message: "The app is not authorized to use location services.")
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    // Фокус карты на местоположение пользователя
    func showUserLocation(mapView: MKMapView) {
        
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Строим маршрут от местоположения пользователя до заведения
    func getDirections(mapView: MKMapView, previousLocation: (CLLocation) -> ()) {
        
        guard let location = locationManager.location?.coordinate else {
            showAlertController(title: "Error", message: "Current location is not found")
            return
        }
        
        locationManager.startUpdatingLocation()
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude))
        
        guard let request = createDirectionsRequest(from: location) else {
            showAlertController(title: "Error", message: "Destination not found")
            return
        }
        
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions, mapView: mapView)
        directions.calculate { (response, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.showAlertController(title: "Error", message: "Directions is not available")
                return
            }
            
            if let minRoute = response.routes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime }) {
                let distance = String(format: "%.1f",  minRoute.distance / 1000 )
                let timeInterval = String(format: "%.f", minRoute.expectedTravelTime / 60 )

                self.mapVC?.distanceTimeLable.text = "Расстояние \(distance) км, Время в пути \(timeInterval) мин"
            }
                        
            for route in response.routes {
                mapView.addOverlay(route.polyline)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
//
//                let distance = String(format: "%.1f",  route.distance / 1000 )
//                let timeInterval = String(format: "%.f", route.expectedTravelTime / 60 )
//
//
//                self.mapVC.distanceTimeLable.text = "Расстояние \(distance) км, Время в пути \(timeInterval) мин"
//
//                print("Расстояние до места: \(distance) км.")
//                print("Время в пути составит: \(timeInterval) мин.")
            }
        }
    }
    
    // Настройка запроса для расчета маршрута
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        guard let destinationCoordinate = placeCoordinate else { return nil }
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    // Меняем отображаемую зону обалсти карты в соответствии с перемещением пользователя
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation:
        CLLocation) -> ()) {
        
        guard let location = location else { return }
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: location) > 50 else { return }
        
        closure(center)
    }
    
    // Сброс всех ранее построенных маршрутов перед построением нового
    func resetMapView (withNew directions: MKDirections, mapView: MKMapView) {
        
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
        directionsArray.removeAll()
    }
    
    //  Определение центра отображаемой области карты
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func showAlertController(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alertController, animated: true)
    }
}
