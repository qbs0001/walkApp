//
//  ViewController.swift
//  walkApp
//
//  Created by 0001 QBS on 2020/06/03.
//  Copyright © 2020 qbs0001. All rights reserved.
//

import CoreLocation
import FloatingPanel
import MapKit
import UIKit
import SVProgressHUD

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet var walkButton: UIButton!
    @IBOutlet var mapView: MKMapView!
    // 位置情報
    var locManager: CLLocationManager!
    // マップ表示の排他用変数
    //var myLock = NSLock()
    // 現在地の座標
    var latitudeNow: String = ""
    var longitudeNow: String = ""
    // アノテーションを格納する配列
    var annotationArray: [MKAnnotation] = []
    // オーバーレイを格納する配列
    var overlayArray: [MKOverlay] = []
    
    // 座標の配列
    var coordinatesArray = [
        ["name": "スタート地点（現在地）", "lat": 0, "lon": 0],
        ["name": "ゴール地点", "lat": 0, "lon": 0],
    ]
    
    // セミモーダルのクラス変数asa
    var floatingPanelController: FloatingPanelController!
    // セミモーダルビューとなるViewControllerを生成し、contentViewControllerとしてセットする
    let semiModalViewController = SemiModalViewController()
    
    // 標準のトラッキングボタン
    var trakingBtn: MKUserTrackingButton!
    
    // サブモーダルに表示するラベル用の変数
    var hosu: Int = 0
    var time: Int = 0
    var dist: Int = 0
    var kcal: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 現在地変数を初期化
        locManager = CLLocationManager()
        // delegateとしてself(自インスタンス)を設定
        locManager.delegate = self
        
        // 位置情報の使用の許可を得る
        locManager.requestWhenInUseAuthorization()
        // 位置情報の使用が許可された場合
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            // 使用中に許可されている場合は、位置情報の取得を開始する。
            case .authorizedWhenInUse:
                // 座標の表示
                locManager.startUpdatingLocation()
            default:
                break
            }
        }
        
        // 画面（地図）の初期化
        initMap()
        
        // セミモーダルの準備
        floatingPanelController = FloatingPanelController()
        // Delegateを設定
        floatingPanelController.delegate = self
        // 角を丸くする
        floatingPanelController.surfaceView.cornerRadius = 6.0
        // セミモーダルビューを表示する
        floatingPanelController.set(contentViewController: semiModalViewController)
        // floatingPanelController.addPanel(toParent: self, belowView: nil, animated: false)
        floatingPanelController.addPanel(toParent: self)
    }
    
    func initMap() {
        // 縮尺を設定
        var region: MKCoordinateRegion = mapView.region
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        mapView.setRegion(region, animated: true)
        
        // 現在位置表示の有効化
        mapView.showsUserLocation = true
        // 現在位置設定（ユーザの位置を中心とする）
        mapView.userTrackingMode = .follow
        
        // トラッキングボタンを定義
        trakingBtn = MKUserTrackingButton(mapView: mapView)
        // デバイスの画面サイズを取得する
        let dispSize: CGSize = UIScreen.main.bounds.size
        // 画面の高さ
        let height = Int(dispSize.height)
        // 画面の幅
        let width = Int(dispSize.width)
        // トラッキングボタンを画面の左下に追加
        trakingBtn.frame = CGRect(x: 15, y: height - 100, width: 40, height: 40)
        trakingBtn.layer.backgroundColor = UIColor(white: 1, alpha: 0.5).cgColor
        view.addSubview(trakingBtn)
        
        // スケール変数を定義
        let scale = MKScaleView(mapView: mapView)
        // 画面の左上にせ追加
        scale.frame.origin.x = 15
        scale.frame.origin.y = 45
        scale.legendAlignment = .leading
        view.addSubview(scale)
        
        // ウォークボタンの位置
        walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 110, width: 60, height: 60)
        // ウォークボタンの背景
        walkButton.backgroundColor = .white
        // ウォークボタンを丸くする
        walkButton.layer.cornerRadius = 60 * 0.5
        walkButton.clipsToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // セミモーダルビューを非表示にする
        floatingPanelController.removePanelFromParent(animated: true)
    }
    
    // ウォークボタンが押下された時
    @IBAction func walkButtonTap(_ sender: Any) {
        print("DBG\(latitudeNow)")
        print("DBG\(longitudeNow)")
        
        // 現在地の緯度経度をスタートに設定
        coordinatesArray[0]["lat"] = Double(latitudeNow)
        coordinatesArray[0]["lon"] = Double(longitudeNow)
        // 現在地からランダムな位置の緯度経度をゴールに設定
        coordinatesArray[1]["lat"] = Double(latitudeNow)! + Double.random(in: -0.01...0.01)
        coordinatesArray[1]["lon"] = Double(longitudeNow)! + Double.random(in: -0.01...0.01)
        
        // delegateとしてself(自インスタンス)を設定
        mapView.delegate = self
        
        //HUDを表示
        SVProgressHUD.show(withStatus: "ルート探索中")
        // 地図を作成
        makeMap()
        //HUDを非表示
        SVProgressHUD.dismiss(withDelay: 0.1)
    }
    
    func makeMap() {
        // マップの表示域を設定
        // マップの中心を配列の一番目に
        let coordinate = CLLocationCoordinate2DMake(coordinatesArray[0]["lat"] as! CLLocationDegrees, coordinatesArray[0]["lon"] as! CLLocationDegrees)
        // マップの範囲
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        // 中心と範囲を設定
        let region = MKCoordinateRegion(center: coordinate, span: span)
        // 反映
        mapView.setRegion(region, animated: true)
        
        // 緯度経度値をもつ構造体を生成（ルート用）
        var routeCoordinates: [CLLocationCoordinate2D] = []
        
        // 前回設定したピンを削除する
        mapView.removeAnnotations(annotationArray)
        annotationArray = []
        
        // 配列分繰り返す
        for i in 0..<coordinatesArray.count {
            // アノテーションを生成
            let annotation = MKPointAnnotation()
            // 配列の緯度経度を設定
            let annotationCoordinate = CLLocationCoordinate2DMake(coordinatesArray[i]["lat"] as! CLLocationDegrees, coordinatesArray[i]["lon"] as! CLLocationDegrees)
            // ピンの吹き出しに名前が出るようにアノテーションに設定
            annotation.title = coordinatesArray[i]["name"] as? String
            // 緯度経度をアノテーションに設定
            annotation.coordinate = annotationCoordinate
            
            // ルートの地点として登録
            routeCoordinates.append(annotationCoordinate)
            
            // 削除用にアノテーションを配列に格納する
            annotationArray.append(annotation)
            
            // マップにピンを立てる
            mapView.addAnnotation(annotation)
        }
        
        // ルート用の変数を生成
        var myRoute: MKRoute!
        // ルート提供をリクエスト
        let directionsRequest = MKDirections.Request()
        
        // ルート地点を格納する配列
        var placemarks = [MKMapItem]()
        // routeCoordinatesの配列からMKMapItemの配列に変換
        for item in routeCoordinates {
            let placemark = MKPlacemark(coordinate: item, addressDictionary: nil)
            placemarks.append(MKMapItem(placemark: placemark))
        }
        // 移動手段に徒歩を設定
        directionsRequest.transportType = .walking
        // 要素の番号と要素の値を取り出して、ループ
        for (k, item) in placemarks.enumerated() {
            // 番号が、最後ではない場合
            if k < (placemarks.count - 1) {
                // 自分をスタート地点とする
                directionsRequest.source = item // スタート地点
                // 目標地点を次の番号とする
                directionsRequest.destination = placemarks[k + 1] // 目標地点
                // スタート地点と目標地点を設定する
                let direction = MKDirections(request: directionsRequest)
                // ルートを探索
                direction.calculate(completionHandler: { response, error in
                    if error == nil {
                        // 最初のルートを設定
                        myRoute = response?.routes[0]
                        
                        // 前回表示したオーバーレイを削除する
                        self.mapView.removeOverlays(self.overlayArray)
                        self.overlayArray = []
                        // ルートを描画
                        self.mapView.addOverlay(myRoute.polyline, level: .aboveRoads) // mapViewに絵画
                        // 削除用にオーバーレイを配列に格納する
                        self.overlayArray.append(myRoute.polyline)
                        
                        // 地図をルート全体が表示できるスケールに変更する
                        let rect = myRoute.polyline.boundingMapRect
                        // print("DBG:\(MKCoordinateRegion(rect).span)")
                        // print("DBG:\(Double(MKCoordinateRegion(rect).span.latitudeDelta) * 1.5)")
                        // self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                        
                        var region: MKCoordinateRegion = self.mapView.region
                        // オーバーレイの中心を設定する
                        region.center = MKCoordinateRegion(rect).center
                        // ピンが見切れるので、スパンを調整する
                        region.span.latitudeDelta = Double(MKCoordinateRegion(rect).span.latitudeDelta) * 1.5
                        region.span.longitudeDelta = Double(MKCoordinateRegion(rect).span.longitudeDelta) * 1.5
                        // マップを描画する
                        self.mapView.setRegion(region, animated: true)
                        
                        // ルート情報から、歩数、時間、距離、カロリをサブモーダルに表示するラベル用変数に格納する
                        self.hosu = Int(myRoute.distance) * 1000 / 765
                        self.time = Int(myRoute.expectedTravelTime) / 60
                        self.dist = Int(myRoute.distance)
                        self.kcal = Int(Double(myRoute.distance) * 1000 / 765 * 0.035)
                        
                        print("DBG歩数:\(self.hosu)歩")
                        print("DBG分:\(self.time)分")
                        print("DBG距離:\(self.dist)m")
                        print("DBGカロリ:\(self.kcal)kcal")
                        
                        // ラベル変数のテキストを更新する
                        self.semiModalViewController.hosuLabel.text = "\(self.hosu)歩"
                        self.semiModalViewController.infoLabel.text = "\(self.time)分　\(self.dist)m　\(self.kcal)kcal　"
                        // 位置情報を最新化する
                        self.semiModalViewController.editLabel()
                        // サブモーダルを更新する
                        self.floatingPanelController.reloadInputViews()
                        // サブモーダルに情報を表示するため、位置をハーフにする
                        self.floatingPanelController.move(to: .half, animated: true)
                        
                        // サブモーダルの位置に合わせて、各種ボタンの位置を調整する
                        let dispSize: CGSize = UIScreen.main.bounds.size
                        let height = Int(dispSize.height)
                        let width = Int(dispSize.width)
                        
                        self.walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 210, width: 60, height: 60)
                        self.trakingBtn.frame = CGRect(x: 15, y: height - 195, width: 40, height: 40)
                    }
                })
            }
        }
    }
    
    // 常に現在地を取得する
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latStr = (locations.last?.coordinate.latitude.description)!
        let lonStr = (locations.last?.coordinate.longitude.description)!
        
        latitudeNow = String(latStr)
        longitudeNow = String(lonStr)
        
        print("DBGlat : " + latStr)
        print("DBGlon : " + lonStr)
        
        // mapView.userTrackingMode = .follow
        // updateCurrentPos((locations.last?.coordinate)!)
        // myLock.lock()
        // myLock.unlock()
    }
    
//    func updateCurrentPos(_ coordinate: CLLocationCoordinate2D) {
//        var region: MKCoordinateRegion = mapView.region
//        region.center = coordinate
//        mapView.setRegion(region, animated: true)
//    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // 吹き出しで情報を表示出来るように
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    // ピンを繋げている線の幅や色を調整
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let route: MKPolyline = overlay as! MKPolyline
        let routeRenderer = MKPolylineRenderer(polyline: route)
        routeRenderer.strokeColor = UIColor(red: 1.00, green: 0.35, blue: 0.30, alpha: 0.8)
        routeRenderer.lineWidth = 3.0
        return routeRenderer
    }
}

// FloatingPanelControllerDelegate を実装してカスタマイズしたレイアウトを返す
extension ViewController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return CustomFloatingPanelLayout()
    }
    
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        let dispSize: CGSize = UIScreen.main.bounds.size
        let height = Int(dispSize.height)
        let width = Int(dispSize.width)
        
        // セミモーダルビューの各表示パターンの高さに応じて処理を実行する
        switch targetPosition {
        case .tip:
            print("tip")
            // ボタンの位置をtipに調整する
            walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 110, width: 60, height: 60)
            trakingBtn.frame = CGRect(x: 15, y: height - 100, width: 40, height: 40)
        case .half:
            print("half")
            // ボタンの位置をhalfに調整する
            walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 210, width: 60, height: 60)
            trakingBtn.frame = CGRect(x: 15, y: height - 195, width: 40, height: 40)
        case .full:
            print("full")
        // fullは、現在使わない
        default: return
        }
    }
}

class CustomFloatingPanelLayout: FloatingPanelLayout {
    // セミモーダルビューの初期位置
    var initialPosition: FloatingPanelPosition {
        // 初期表示は、tipにする
        return .tip
    }
    
    var topInteractionBuffer: CGFloat { return 0.0 }
    var bottomInteractionBuffer: CGFloat { return 0.0 }
    
    // セミモーダルビューの各表示パターンの高さを決定するためのInset
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .half: return 108.0
        case .tip: return 10.0
        default: return nil
        }
    }
    
    // セミモーダルビューの背景Viewの透明度
    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return 0.0
    }
    
    // サポートする位置
    var supportedPositions: Set<FloatingPanelPosition> {
        // fullは、現在使わない
        return [.half, .tip]
    }
}
