//
//  UIColor-Extension.swift
//  LoginWithFirebaseApp
//
//  Created by 野津天志 on 2021/02/12.
//

import UIKit

//仕事をするときに便利
//デザインの人からもらった色の値を直接使うことができる(rgbなど)
extension UIColor{
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor{
        return self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}
