//
//  JournalEntryTableViewCell.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/30/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit
import Kingfisher

class JournalEntryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var containingView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var textData : UILabel!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    var entry : JournalEntry?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        if let button = self.imageButton {
            button.imageView?.contentMode = .scaleAspectFill
        }
        
        // round top corners of image, as the clip to bounds is set to false on containing
        // CardView, causing the corner to leak over the bounds without this workaround
        if let img = thumbnailImage {
            img.layer.cornerRadius = 3
            img.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setValues(entry : JournalEntry) {
        self.entry = entry
        self.textData.text = entry.caption
        self.date.text = entry.date?.shortWithTime
        if let temp = entry.temperature, let w = entry.weatherIcon {
            let tstr = String(format: "%.0f°", temp)
            self.temperature.text = tstr
            let iconUrl = "https://openweathermap.org/img/wn/\(w)@2x.png"
            self.weatherImage.kf.setImage(with: URL(string: iconUrl))
            self.temperature.isHidden = false
            self.weatherImage.isHidden = false
        } else {
            self.temperature.isHidden = true
            self.weatherImage.isHidden = true
        }
    }
    
}
