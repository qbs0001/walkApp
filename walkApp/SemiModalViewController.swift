//
//  SemiModalViewController.swift
//  walkApp
//
//  Created by 0001 QBS on 2020/06/09.
//  Copyright © 2020 qbs0001. All rights reserved.
//

import UIKit

class SemiModalViewController: UIViewController {
    var hosuLabel = UILabel()
    var infoLabel = UILabel()
    var startButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // 背景色
        view.backgroundColor = UIColor.white

        // ラベルの初期値
        hosuLabel.text = ""
        infoLabel.text = ""
        // ラベルの配置
        editLabel()

        // ラベルをサブモーダルに追加する
        view.addSubview(hosuLabel)
        view.addSubview(infoLabel)
        
        // 決定ボタンの配置
        editButton()
        // デフォルトは、非表示
        startButton.isHidden = true
        // 決定ボタンをサブモーダルに追加する
        view.addSubview(startButton)
    }

    func editLabel() {
        // 画面の幅を取得
        let width = Float(UIScreen.main.bounds.size.width)

        // 文字色
        hosuLabel.textColor = .systemBlue
        // フォント
        hosuLabel.font = UIFont.boldSystemFont(ofSize: 25)
        // 中央揃え
        hosuLabel.textAlignment = .center
        // 幅を文字列とする
        hosuLabel.sizeToFit()
        // 幅は、サブモーダルの真ん中に配置
        let widthGap1 = (width - Float(hosuLabel.frame.width)) / 2
        hosuLabel.frame = CGRect(x: CGFloat(widthGap1),
                                 y: 40,
                                 width: hosuLabel.frame.width,
                                 height: hosuLabel.frame.height)
        // 文字色
        infoLabel.textColor = .darkGray
        // フォント
        infoLabel.font = UIFont.systemFont(ofSize: 15)
        // 中央揃え
        infoLabel.textAlignment = .center
        // 幅を文字列とする
        infoLabel.sizeToFit()
        // 幅は、サブモーダルの真ん中に配置
        let widthGap2 = (width - Float(infoLabel.frame.width)) / 2
        infoLabel.frame = CGRect(x: CGFloat(widthGap2),
                                 y: 80,
                                 width: infoLabel.frame.width,
                                 height: infoLabel.frame.height)
    }
    
    func editButton() {
        
        // デバイスの画面サイズを取得する
        let dispSize: CGSize = UIScreen.main.bounds.size
        // 画面の幅
        let width = Int(dispSize.width)
        
        // 決定ボタンの位置
        startButton.frame = CGRect(x: (width * 4 / 5) - 20, y: 40, width: 60, height: 60)
        // 決定ボタンの背景
        startButton.backgroundColor = .white
        
        // 決定ボタンの画像
        let buttonImage = UIImage(systemName: "checkmark.rectangle.fill")
        
        startButton.setImage(buttonImage, for: .normal)
        startButton.imageView?.contentMode = .scaleAspectFit
        startButton.contentHorizontalAlignment = .fill
        startButton.contentVerticalAlignment = .fill
        
        startButton.alpha = 0.9

        
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
