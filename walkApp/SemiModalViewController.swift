//
//  SemiModalViewController.swift
//  walkApp
//
//  Created by 0001 QBS on 2020/06/09.
//  Copyright © 2020 qbs0001. All rights reserved.
//

import UIKit

class SemiModalViewController: UIViewController {
    
    var label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //背景色
        self.view.backgroundColor = UIColor.white
        
        
        
        label.frame = CGRect(x:150,y:200,width:160,height:30)
        label.text = "Test"
        self.view.addSubview(label)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
