//
//  HistoricalViewController.swift
//  Carleton150

import UIKit
import GoogleMaps
import CoreLocation
import MapKit
import Reachability

class HistoricalViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    @IBOutlet weak var recenterButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
	@IBOutlet weak var connectionIndicator: UIActivityIndicatorView!
	@IBOutlet weak var connectionLabel: UILabel!
	@IBOutlet weak var connectionView: UIView!
	
	let locationManager: CLLocationManager = CLLocationManager()
	var reach: Reachability?
	var networkMonitor: Reachability!
    var landmarks: [String : Landmark]!
    var timer: NSTimer!
    var shouldReload: Bool = false
	
	
    /**
        Upon load of this view, start the location manager and
        set the camera on the map view to focus on Carleton.
     */
    override func viewDidLoad() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
       
        // if the user is opening the app for the first time,
        if !defaults.boolForKey("hasSeenTutorial") {
            defaults.setBool(true, forKey: "hasSeenTutorial")
            // show the tutorial
            self.performSegueWithIdentifier("tutorial", sender: nil)
        }
        defaults.synchronize()
		
		// initialize geofences dictionary
		self.landmarks = Dictionary<String,Landmark>()
        
        mapView.bringSubviewToFront(self.recenterButton)
		
        // set properties for the navigation bar
        Utils.setUpNavigationBar(self)
        
        // set up the location manager
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestAlwaysAuthorization()
	
        // set up current map location based on the user's location, if possible.
		if let curLocation = self.locationManager.location {
			self.mapView.camera = GMSCameraPosition.cameraWithTarget(curLocation.coordinate, zoom: 16)
		} else {
			mapView.camera = GMSCameraPosition.cameraWithLatitude(44.4619, longitude: -93.1538, zoom: 16)
		}
		
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		self.networkMonitor = appDelegate.networkMonitor
		
		// set up the map view
		mapView.delegate = self
        mapView.myLocationEnabled = true
		
        // set up the tiling for the map
        Utils.setUpTiling(mapView)
        
        // triggers page to reload geofences every 30 minutes
        timer = NSTimer.scheduledTimerWithTimeInterval(1800, target: self, selector: #selector(self.setReload), userInfo: nil, repeats: true)
	}
    
    override func viewDidAppear(animated: Bool) {
        if shouldReload {
            reloadLandmarks()
        }
    }
    
    
    @IBAction func showHelp(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("tutorial", sender: nil)
    }
    
    
    @IBAction func recenterOnCarleton(sender: AnyObject) {
		mapView.camera = GMSCameraPosition.cameraWithLatitude(44.4619, longitude: -93.1538, zoom: 16)
    }
    
    @IBAction func recenterOnLocation(sender: UIBarButtonItem) {
        if let coordinates = self.locationManager.location?.coordinate {
            mapView.camera = GMSCameraPosition.cameraWithLatitude(coordinates.latitude, longitude: coordinates.longitude, zoom: 16)
        }
    }
    
    func clearLandmarks() {
        for landmark in self.landmarks {
            landmark.1.marker.map = nil
        }
        self.landmarks = [:]
    }
    
    func setReload() {
        shouldReload = true
    }
    
    func reloadLandmarks() {
        clearLandmarks()
        loadLandmarks()
    }
    
    /**
        Requests the geofences from the server. 
     */
    func loadLandmarks() {
        HistoricalDataService.getLandmarks() { success, result in
            if success {
                for eventGroup in result {
                    let identifier = eventGroup.0
                    let events = eventGroup.1
                    let coordinate = events[0].location
                    let landmark = Landmark(coordinate: coordinate, identifier: identifier, events: events)
                    if self.landmarks[identifier] == nil {
                        self.landmarks[identifier] = landmark
                    }
                    landmark.displayLandmark(self.mapView)
                }
            }
        }
    }
	
    
	/**
		Called by observer every time the internet connection changes.
        Toggles UI elements to show the current state of the connection.
		
		Parameters
			- notification: notification sent by observer
	*/
	func connectionStatusChanged(notification: NSNotification) {
		if self.networkMonitor!.isReachableViaWiFi() || self.networkMonitor!.isReachableViaWWAN() {
            self.connectionLabel.hidden = true
            self.connectionIndicator.stopAnimating()
            self.connectionIndicator.hidden = true
            self.connectionView.hidden = true
            self.mapView.sendSubviewToBack(self.connectionView)
            self.loadLandmarks()
		} else {
			self.connectionLabel.hidden = false
			self.connectionIndicator.startAnimating()
			self.connectionIndicator.hidden = false
			self.connectionView.hidden = false
            self.mapView.bringSubviewToFront(self.connectionView)
		}
	}
	
	
    /**
        If the view is about to appear, lower the threshold
        for requests so that smaller distance differences will
        cause a request to be triggered, and then update the 
        geofences based on the curent location.
     */
	override func viewWillAppear(animated: Bool) {
		// Setup networking monitoring
		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(HistoricalViewController.connectionStatusChanged(_:)),
			name: kReachabilityChangedNotification,
			object: nil
		)
		// check to see if connected
		self.connectionStatusChanged(
			NSNotification(
				name: "Initial Connection Check",
				object: nil
			)
		)
	}

    
    /**
        Prepares for a segue to the detail view for a particular point of
        interest on the map.
     
        Parameters: 
            - segue:  The segue that was triggered by user. If this is not the
                      segue to the landmarkDetail view, then don't do anything.
                      segue.
     
            - sender: The sender, in our case, will be one of the Google Maps markers
                      that was pressed, which will in turn have data associated with 
                      it that will given to the landmark detail view.
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showTimeline" {
			let destinationController = (segue.destinationViewController as! TimelineViewController)
			destinationController.parentVC = self
			
			if let landmarkName = (sender?.title)! as String! {
				destinationController.selectedGeofence = landmarkName.stringByReplacingOccurrencesOfString("&amp;", withString: "&")
				if let landmark = landmarks[landmarkName] {
					destinationController.timeline = landmark.events
				}
			}
        }
    }
	
    
    /**
        The function immediately called by the location manager that 
        begins keeping track of location for the various geofence triggers 
        that occur while walking around campus.
     
        Parameters: 
            - manager:                      The location manager that was
                                            started within this view.
     
            - didChangeAuthorizationStatus: The current authorization status for the user
                                            determining whether we can use location.
     */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways {
            locationManager.startUpdatingLocation()
            mapView.myLocationEnabled = true
        }
    }
    
    
    /**
        Selects a marker and shows the popover upon a tap from the user.
     
        Parameters:
            - mapView: The Google Maps view the marker is attached to.
     
            - didTapMarker: The marker that was tapped by the user.
     */
	func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        self.performSegueWithIdentifier("showTimeline", sender: marker)
		return true
	}
}