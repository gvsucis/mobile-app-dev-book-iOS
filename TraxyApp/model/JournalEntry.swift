//
//  JournalEntry.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/29/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import Foundation

enum EntryType : Int {
    case text = 1
    case photo
    case audio
    case video
}

struct JournalEntry {
    var key : String?
    var type: EntryType?
    var caption : String?
    var url : String
    var thumbnailUrl : String
    var date : Date?
    var lat : Double?
    var lng : Double?
    var temperature: Double?
    var weatherIcon: String? 
    
    init(key: String?, type: EntryType?, caption: String?, url: String,
         thumbnailUrl: String, date: Date?, lat: Double?, lng: Double?, temperature: Double? = nil, weatherIcon: String? = nil)
    {
        self.key = key
        self.type = type
        self.caption = caption
        
        self.date = date
        self.lat = lat
        self.lng = lng
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.temperature = temperature
        self.weatherIcon = weatherIcon
    }
}

