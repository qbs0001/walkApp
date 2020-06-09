//
//  ViewController.swift
//  walkApp
//
//  Created by 0001 QBS on 2020/06/03.
//  Copyright © 2020 qbs0001. All rights reserved.
//

import CoreLocation
import MapKit
import UIKit
import FloatingPanel

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var walkButton: UIButton!
    @IBOutlet var mapView: MKMapView!
    // 位置情報
    var locManager: CLLocationManager!
    // 拡大率
    let goldenRatio = 1.618
    // マップ表示の排他用変数
    var myLock = NSLock()
    

    
    //現在地の座標
    var latitudeNow: String = ""
    var longitudeNow: String = ""
    
    var annotationArray: [MKAnnotation] = []
    var overlayArray: [MKOverlay] = []
    
    //座標の配列
    var coordinatesArray = [
        ["name":"スタート地点（現在地）",    "lat":0,  "lon":0],
        ["name":"ゴール地点",   "lat":33.459531,  "lon": 130.546481],

    ]
    
    //セミモーダルのクラス変数
    var floatingPanelController: FloatingPanelController!
    // セミモーダルビューとなるViewControllerを生成し、contentViewControllerとしてセットする
    let semiModalViewController = SemiModalViewController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 変数を初期化
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
        
        // 地図の初期化
        initMap()
        
        //セミモーダルの準備
        floatingPanelController = FloatingPanelController()
        // Delegateを設定
        floatingPanelController.delegate = self
        //角を丸くする
        floatingPanelController.surfaceView.cornerRadius = 6.0

        floatingPanelController.set(contentViewController: semiModalViewController)
        // セミモーダルビューを表示する
        //floatingPanelController.addPanel(toParent: self, belowView: nil, animated: false)
        floatingPanelController.addPanel(toParent: self)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // セミモーダルビューを非表示にする
        floatingPanelController.removePanelFromParent(animated: true)
    }
    
    
    
      @IBAction func walkButtonTap(_ sender: Any) {
    
          print("DBG\(self.latitudeNow)")
          print("DBG\(self.longitudeNow)")
        
        
        
        coordinatesArray[0]["lat"] = Double(self.latitudeNow)
        coordinatesArray[0]["lon"] = Double(self.longitudeNow)
        
        coordinatesArray[1]["lat"] = Double(self.latitudeNow)! + Double.random(in: -0.01...0.01)
        coordinatesArray[1]["lon"] = Double(self.longitudeNow)! + Double.random(in: -0.01...0.01)
        


          // delegateとしてself(自インスタンス)を設定
          self.mapView.delegate = self
          // 地図を作成
          makeMap()
          
          
      }
    
    func makeMap(){
        //マップの表示域を設定
        //マップの中心を配列の一番目に
        let coordinate = CLLocationCoordinate2DMake(coordinatesArray[0]["lat"] as! CLLocationDegrees, coordinatesArray[0]["lon"] as! CLLocationDegrees)
        //マップの範囲
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        //中心と範囲を設定
        let region = MKCoordinateRegion(center: coordinate, span: span)
        //反映
        self.mapView.setRegion(region, animated: true)
        
        //緯度経度値をもつ構造体を生成（ルート用）
        var routeCoordinates: [CLLocationCoordinate2D] = []
        
        //前回設定したピンを削除する
        self.mapView.removeAnnotations(annotationArray)
        self.annotationArray = []
        
        //配列分繰り返す
        for i in 0..<coordinatesArray.count {
            //アノテーションを生成
            let annotation = MKPointAnnotation()
            //配列の緯度経度を設定
            let annotationCoordinate = CLLocationCoordinate2DMake(coordinatesArray[i]["lat"] as! CLLocationDegrees, coordinatesArray[i]["lon"] as! CLLocationDegrees)
            //ピンの吹き出しに名前が出るようにアノテーションに設定
            annotation.title = coordinatesArray[i]["name"] as? String
            //緯度経度をアノテーションに設定
            annotation.coordinate = annotationCoordinate
            //ルートの地点として登録
            routeCoordinates.append(annotationCoordinate)
            
            //削除用にアノテーションを配列に格納する
            self.annotationArray.append(annotation)
            
            //マップにピンを立てる
            self.mapView.addAnnotation(annotation)
        }
        
        //ルート用の変数を生成
        var myRoute: MKRoute!
        //ルート提供をリクエスト
        let directionsRequest = MKDirections.Request()
        
        //ルート地点を格納する配列
        var placemarks = [MKMapItem]()
        //routeCoordinatesの配列からMKMapItemの配列に変換
        for item in routeCoordinates{
            let placemark = MKPlacemark(coordinate: item, addressDictionary: nil)
            placemarks.append(MKMapItem(placemark: placemark))
        }
        //移動手段に徒歩を設定
        directionsRequest.transportType = .walking
        //要素の番号と要素の値を取り出して、ループ
        for (k, item) in placemarks.enumerated(){
            //番号が、最後ではない場合
            if k < (placemarks.count - 1){
                //自分をスタート地点とする
                directionsRequest.source = item //スタート地点
                //目標地点を次の番号とする
                directionsRequest.destination = placemarks[k + 1] //目標地点
                //スタート地点と目標地点を設定する
                let direction = MKDirections(request: directionsRequest)
                //ルートを探索
                direction.calculate(completionHandler: {(response, error) in
                    if error == nil {
                        //最初のルートを設定
                        myRoute = response?.routes[0]
                        print("DBG距離:\(myRoute.distance)m")
                        print("DBG秒:\(Int(myRoute.expectedTravelTime)/60)分")
                        
                        self.semiModalViewController.label.text = "DBG距離:\(myRoute.distance)m"
                        self.floatingPanelController.set(contentViewController: self.semiModalViewController)
                        
                        //前回表示したオーバーレイを削除する
                        self.mapView.removeOverlays(self.overlayArray)
                        self.overlayArray = []
                        //ルートを描画
                        self.mapView.addOverlay(myRoute.polyline, level: .aboveRoads) //mapViewに絵画
                        //削除用にオーバーレイを配列に格納する
                        self.overlayArray.append(myRoute.polyline)
                        
                        // 地図をルート全体が表示できるスケールに変更する
                        let rect = myRoute.polyline.boundingMapRect
                        //print("DBG:\(MKCoordinateRegion(rect).span)")
                        //print("DBG:\(Double(MKCoordinateRegion(rect).span.latitudeDelta) * 1.5)")
                        //self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                        
                        var region: MKCoordinateRegion = self.mapView.region
                        //オーバーレイの中心を設定する
                        region.center = MKCoordinateRegion(rect).center
                        //ピンが見切れるので、スパンを調整する
                        region.span.latitudeDelta = Double(MKCoordinateRegion(rect).span.latitudeDelta) * 1.5
                        region.span.longitudeDelta = Double(MKCoordinateRegion(rect).span.longitudeDelta) * 1.5
                        //マップを描画する
                        self.mapView.setRegion(region, animated: true)
                    }
                })
            }
        }
        //ルートがマップに収まるように
//        if let firstOverlay = self.mapView.overlays.first{
//            let rect = self.mapView.overlays.reduce(firstOverlay.boundingMapRect, {$0.union($1.boundingMapRect)})
//            self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 35, left: 35, bottom: 35, right: 35), animated: true)
//        }
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
        
        let trakingBtn = MKUserTrackingButton(mapView: mapView)
        // デバイスの画面サイズを取得する
        let dispSize: CGSize = UIScreen.main.bounds.size
        let height = Int(dispSize.height)
        trakingBtn.frame = CGRect(x: 15, y: height - 100, width: 40, height: 40)
        trakingBtn.layer.backgroundColor = UIColor(white: 1, alpha: 0.5).cgColor
        view.addSubview(trakingBtn)
        
        let scale = MKScaleView(mapView: mapView)
        
        scale.frame.origin.x = 15
        scale.frame.origin.y = 45
        scale.legendAlignment = .leading
        
        view.addSubview(scale)
    }
    
    
    

    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latStr = (locations.last?.coordinate.latitude.description)!
        let lonStr = (locations.last?.coordinate.longitude.description)!

        self.latitudeNow = String(latStr)
        self.longitudeNow = String(lonStr)

        print("DBGlat : " + latStr)
        print("DBGlon : " + lonStr)

        
        //mapView.userTrackingMode = .follow
        
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
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true //吹き出しで情報を表示出来るように
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    //ピンを繋げている線の幅や色を調整
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let route: MKPolyline = overlay as! MKPolyline
        let routeRenderer = MKPolylineRenderer(polyline: route)
        routeRenderer.strokeColor = UIColor(red:1.00, green:0.35, blue:0.30, alpha:1.0)
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

        // セミモーダルビューの各表示パターンの高さに応じて処理を実行する
        switch targetPosition {
        case .tip:
            print("tip")
            let dispSize: CGSize = UIScreen.main.bounds.size
            let height = Int(dispSize.height)
            let width = Int(dispSize.width)
            walkButton.frame = CGRect(x: width/2, y: height - 100, width: 40, height: 40)
        case .half:
            print("half")
        case .full:
            print("full")
        default: return
        }
    }
    
}

class CustomFloatingPanelLayout: FloatingPanelLayout {

    // セミモーダルビューの初期位置
    var initialPosition: FloatingPanelPosition {
        return .tip
    }

    var topInteractionBuffer: CGFloat { return 0.0 }
    var bottomInteractionBuffer: CGFloat { return 0.0 }

    // セミモーダルビューの各表示パターンの高さを決定するためのInset
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .half: return 216.0
        case .tip: return 10.0
        default: return nil
        }
    }

    // セミモーダルビューの背景Viewの透明度
    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return 0.0
    }
    

    
}
