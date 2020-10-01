//
//  TraxyMainTableViewCell.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 10/1/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit

class TraxyMainTableViewCell: UITableViewCell {
    @IBOutlet weak var subName: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var translucentView: UIView!
    @IBOutlet weak var coverImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.coverImage.backgroundColor = THEME_COLOR3
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
