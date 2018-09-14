//
//  BoundingBoxView.swift
//  ItemRecognizer
//
//  Created by punyawee  on 14/9/61.
//  Copyright © พ.ศ. 2561 Punyugi. All rights reserved.
//

import UIKit

class BoundingBoxView: UIView {

    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var pctLbl: UILabel!
    
    override func draw(_ rect: CGRect) {
        self.layer.borderColor = #colorLiteral(red: 0.1255, green: 0.698, blue: 0.6667, alpha: 1)
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
    }
    
}
