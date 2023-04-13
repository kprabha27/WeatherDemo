//
//  ViewController.swift
//  WeatherDemo
//
//  Created by Prabhakar Kandala on 06/04/23.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    private var viewModel: WeatherViewModel = WeatherViewModel()
    
    @IBOutlet weak var locationSearchField: UITextField!
    var locationManager = CLLocationManager ()
    var currentLoc = ""
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var weatherDiscriptionLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var wetherImage: UIImageView!
    
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var minTemperatureLabel: UILabel!
    @IBOutlet weak var maxTemperatureLabel: UILabel!
    
    @IBOutlet weak var weatherDetailsStackView: UIStackView!
    var currentlocation : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setScreenThemes()
    }
    
    func setScreenThemes() {
        self.locationSearchField.layer.cornerRadius = 24.0
        self.locationSearchField.layer.borderWidth = 1.0
        self.locationSearchField.layer.borderColor = .init(gray: 1.0, alpha: 1.0)
        self.locationSearchField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: self.locationSearchField.frame.height))
        self.locationSearchField.leftViewMode = .always
        self.locationSearchField.attributedPlaceholder = NSAttributedString(
            string: "Please search location here",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )
        getWeatherForLastSearchLocation()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        DispatchQueue.main.async {
            if CLLocationManager.locationServicesEnabled(){
                self.locationManager.startUpdatingLocation()
            }else {
                self.showLocationDisabledAlert()
            }
        }
    }
    
    func showLocationDisabledAlert()  {
        let alert = UIAlertController(title: "Alert Title", message: "Please enable Location services", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            let appSettings = URL(string: UIApplication.openSettingsURLString)
            if let appSettings = appSettings {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { [self] action in
            //navigationController?.popViewController(animated: true)
            alert.dismiss(animated: true)
        }))
        present(alert, animated: true)
    }
    
    func getWeatherForLastSearchLocation() {
        if AppData.last_search_location != "" {
            getweatherData(for: AppData.last_search_location)
        }else{
            
            getweatherData(for:  currentLocation.current_location)
            
        }
    }
    
    //MARK: - location delegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation :CLLocation = locations[0] as CLLocation
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(userLocation) { (placemarks, error) in
            if (error != nil){
                print("error in reverseGeocode")
            }
            let placemark = placemarks! as [CLPlacemark]
            if placemark.count>0{
                let placemark = placemarks![0]
                print(placemark.locality!)
                print(placemark.administrativeArea!)
                print(placemark.country!)
                currentLocation.current_location = placemark.country!
            }
        }
        self.locationManager.stopUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error)")
    }
}


extension ViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        let numberOfChars = newText?.count ?? 0
        if numberOfChars > 3 {
            getweatherData(for: newText ?? "")
        }
        return true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        getweatherData(for: textField.text ?? "")
        return true
    }
    
}

extension ViewController {
    func getweatherData(for location: String) {
        viewModel.getWeatherReport(location: location)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateUIWithWeatherData()
            AppData.last_search_location = location
            
        }
    }
}

extension ViewController {
    
    func updateUIWithWeatherData() {
        if viewModel.weatherData != nil {
            weatherDetailsStackView.isHidden = false
            locationLabel.text = "\(viewModel.weatherData?.name ?? ""), \(viewModel.weatherData?.country ?? "")"
            weatherDiscriptionLabel.text = viewModel.weatherData?.description
            temperatureLabel.text = "\(String(format:"%.f", viewModel.weatherData?.temp ?? 0.0))°c"
            minTemperatureLabel.text = "\(String(format:"%.f", viewModel.weatherData?.tempMin ?? 0.0))°c"
            maxTemperatureLabel.text = "\(String(format:"%.f", viewModel.weatherData?.tempMax ?? 0.0))°c"
            humidityLabel.text = "\(viewModel.weatherData?.humidity ?? 0)%"
            if let object = viewModel.weatherData?.icon {
                let second = "\(Constants.WEATHER_ICON_URL)\(object)\(".png")"
                self.wetherImage.imageFromUrl(urlString: second)
            }else{
            }
        } else {
            
        }
    }
}
extension UIImageView {
    public func imageFromUrl(urlString: String) {
        if let url = NSURL(string: urlString) {
            let request = NSURLRequest(url: url as URL)
            NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue.main) {
                (response: URLResponse?, data: Data?, error: Error?) -> Void in
                if let imageData = data as Data? {
                    self.image = UIImage(data: imageData)
                }
            }
        }
    }
}
