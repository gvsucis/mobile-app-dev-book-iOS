//
//  WeatherService.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 1/4/21.
//  Copyright © 2021 Jonathan Engelsma. All rights reserved.
//

import Foundation

struct Weather {
    var iconName : String
    var temperature : Double
    
    init(iconName: String, temperature: Double) {
        self.iconName = iconName
        self.temperature = temperature
    }
}

protocol WeatherService {
    func getWeather(forLocation location: (Double, Double),
        completion: @escaping (Weather?) -> Void)
}

