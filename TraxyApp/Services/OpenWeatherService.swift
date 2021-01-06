//
//  OpenWeatherService.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 1/4/21.
//  Copyright © 2021 Jonathan Engelsma. All rights reserved.
//

import Foundation

let sharedOpenWeatherInstance = OpenWeatherService()

class OpenWeatherService: WeatherService {
    
    let API_BASE = "https://api.openweathermap.org/data/2.5/weather"
    var urlSession = URLSession.shared
    
    class func getInstance() -> OpenWeatherService {
        return sharedOpenWeatherInstance
    }
    
    func getWeather(forLocation location: (Double, Double),
        completion: @escaping (Weather?) -> Void)
    {
        let urlStr = API_BASE +
            "?units=imperial&lat=\(location.0)&lon=\(location.1)&appid=\(OPEN_WEATHER_API_KEY)"
        
        let url = URL(string: urlStr)
        
        let task = self.urlSession.dataTask(with: url!) {
            (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let _ = response {
                let parsedObj : Dictionary<String,AnyObject>!
                do {
                    parsedObj = try JSONSerialization.jsonObject(with: data!, options:
                    .allowFragments) as? Dictionary<String,AnyObject>
                    
                    guard let forecast = parsedObj["weather"],
                          let main = parsedObj["main"],
                          let details = forecast[0] as? Dictionary<String, AnyObject>,
                          let iconName = details["icon"] as? String,
                        let temperature = main["temp"] as? Double
                    else {
                        completion(nil)
                        return
                    }
                    
                    let weather = Weather(iconName: iconName, temperature: temperature)
                    completion(weather)
                    
                }  catch {
                    completion(nil)
                }
            }
        }

        task.resume()
    }
}
