//
//  ViewController.swift
//  walkApp
//
//  Created by 0001 QBS on 2020/06/03.
//  Copyright © 2020 qbs0001. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate {
    
    // 位置情報
    var locManager: CLLocationManager!
    // 拡大率
    let goldenRatio = 1.618
    // マップ表示の排他用変数
    var myLock = NSLock()
    

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var trackingButton: UIButton!
    
    let ImageHeadingUp :UIImage? = UIImage(systemName:"eye")
    let ImageScrollMode :UIImage? = UIImage(systemName:"location.north")
    let ImageNorthUp :UIImage? = UIImage(systemName:"location.north.fill")
    
    @IBAction func trackingBtnThouchUp(_ sender: Any) {
        
        print("tracking Button Thouch Up!")
        
        switch mapView.userTrackingMode {
        //ノースアップの場合は、ヘディングアップに変更
        case .follow:
            mapView.userTrackingMode = .followWithHeading
            trackingButton.setImage(ImageHeadingUp, for: .normal)
            break
        //ヘディングアップの場合は、スクロールに変更
        case .followWithHeading:
            mapView.userTrackingMode = .none
            trackingButton.setImage(ImageScrollMode, for: .normal)
            break
        //スクロールの場合は、ノースアップに変更
        default:
            mapView.userTrackingMode = .follow
            trackingButton.setImage(ImageNorthUp, for: .normal)
            break
        }
        
        
    }
    

    
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locManager = CLLocationManager()   // 変数を初期化
        locManager.delegate = self         // delegateとしてself(自インスタンス)を設定
        
        // 位置情報の使用の許可を得る
        locManager.requestWhenInUseAuthorization()
        // 位置情報の使用が許可された場合
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            // 使用中に許可されている場合は、位置情報の取得を開始する。
            case .authorizedWhenInUse:
                // 座標の表示
                locManager.startUpdatingLocation()
                break
            default:
                break
            }
        }
        
        // 地図の初期化
        initMap()
        
    }
    
    func initMap() {
        // 縮尺を設定
        var region:MKCoordinateRegion = mapView.region
        region.span.latitudeDelta = 0.02
        region.span.longitudeDelta = 0.02
        mapView.setRegion(region,animated:true)

        // 現在位置表示の有効化
        mapView.showsUserLocation = true
        // 現在位置設定（ユーザの位置を中心とする）
        mapView.userTrackingMode = .follow
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        let lonStr = (locations.last?.coordinate.longitude.description)!
        let latStr = (locations.last?.coordinate.latitude.description)!

        print("lon : " + lonStr)
        print("lat : " + latStr)
        
        //updateCurrentPos((locations.last?.coordinate)!)
        //myLock.lock()
        // 現在位置設定（ユーザの位置を中心とする）
        switch mapView.userTrackingMode {
        
        //ヘディングアップの場合
        case .followWithHeading:
            mapView.userTrackingMode = .followWithHeading
            break
        //ノースアップの場合
        case .follow:
            mapView.userTrackingMode = .follow
            break
        //スクロールの場合
        default:
            break
        }
        //myLock.unlock()
    }
    
    func updateCurrentPos(_ coordinate:CLLocationCoordinate2D) {
        var region:MKCoordinateRegion = mapView.region
        region.center = coordinate
        mapView.setRegion(region,animated:true)
    }


}

