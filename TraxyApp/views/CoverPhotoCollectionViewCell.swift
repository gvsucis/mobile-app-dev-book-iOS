//
//  CoverPhotoCollectionViewCell.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 1/8/21.
//  Copyright © 2021 Jonathan Engelsma. All rights reserved.
//

import UIKit

class CoverPhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photo: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            self.photo.layer.borderWidth = isSelected ? 5 : 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.photo.layer.borderColor = THEME_COLOR2.cgColor
        isSelected = false
    }
}
