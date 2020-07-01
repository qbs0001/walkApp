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
import SVProgressHUD
import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet var walkButton: UIButton!
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var sliderLabel: UILabel!
    @IBOutlet var walkSlider: UISlider!
    
    // 起動時のスプラッシュ画像と白背景
    var splashImageView: UIImageView!
    var splashBackImageView: UIImageView!
    // 位置情報
    var locManager: CLLocationManager!
    // マップ表示の排他用変数
    // var myLock = NSLock()
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
    
    // 目的地の標高
    var goalElevation: String!
    
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
    
    // 待ちセマフォ
    // var semaphore: DispatchSemaphore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // デバイスの画面サイズを取得する
        let dispSize: CGSize = UIScreen.main.bounds.size
        // 画面の高さ
        let height = Int(dispSize.height)
        // 画面の幅
        let width = Int(dispSize.width)
        
        // スプラッシュ画像の背景用のimageView作成
        splashBackImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        // 中央寄せ
        splashBackImageView.center = view.center
        // 背景は白色
        splashBackImageView.backgroundColor = .white
        // viewに追加
        view.addSubview(splashBackImageView)
        
        // スプラッシュ画像のimageView作成
        splashImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        // 中央寄せ
        splashImageView.center = view.center
        // 画像を設定
        splashImageView.image = UIImage(named: "walkButton")
        // viewに追加
        view.addSubview(splashImageView)
        
        // 現在地変数を初期化
        locManager = CLLocationManager()
        // 現在位置をバックグラウンドでも取得
        locManager.allowsBackgroundLocationUpdates = true
        // delegateとしてself(自インスタンス)を設定
        locManager.delegate = self
        
        // 位置情報の使用の許可を得る
        locManager.requestAlwaysAuthorization()
        // 位置情報の使用が許可された場合
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            // 使用中に許可されている場合は、位置情報の取得を開始する。
            case .authorizedWhenInUse, .authorizedAlways:
                // 座標の表示
                locManager.startUpdatingLocation()
                // 起動時の座標を設定
                latitudeNow = String((locManager.location?.coordinate.latitude)!)
                longitudeNow = String((locManager.location?.coordinate.longitude)!)
                
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
    
    // ビューコントローラの準備完了後に呼び出される
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 80%まで縮小させる
        UIView.animate(withDuration: 0.3,
                       delay: 1.0,
                       options: UIView.AnimationOptions.curveEaseOut,
                       animations: { () in
                           self.splashImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                       }, completion: { _ in
                           
        })
        // 8倍まで拡大する
        UIView.animate(withDuration: 0.2,
                       delay: 1.3,
                       options: UIView.AnimationOptions.curveEaseOut,
                       animations: { () in
                           self.splashImageView.transform = CGAffineTransform(scaleX: 8.0, y: 8.0)
                           self.splashImageView.alpha = 0
                       }, completion: { _ in
                           // アニメーションが終わったらimageViewを消す
                           self.splashImageView.removeFromSuperview()
                           self.splashBackImageView.removeFromSuperview()
        })
    }
    
    func initMap() {
        // delegateとしてself(自インスタンス)を設定
        mapView.delegate = self
        
        // 縮尺を設定
        var region: MKCoordinateRegion = mapView.region
        region.span.latitudeDelta = 0.025
        region.span.longitudeDelta = 0.025
        mapView.setRegion(region, animated: true)
        
        // 現在位置表示の有効化
        mapView.showsUserLocation = true
        // 現在位置設定（ユーザの位置を中心とする）
        mapView.userTrackingMode = .follow
        
        // mapView.tintColor = UIColor.green
        
        // トラッキングボタンを定義
        trakingBtn = MKUserTrackingButton(mapView: mapView)
        // デバイスの画面サイズを取得する
        let dispSize: CGSize = UIScreen.main.bounds.size
        // 画面の高さ
        let height = Int(dispSize.height)
        // 画面の幅
        let width = Int(dispSize.width)
        // トラッキングボタンを画面の左下に追加
        trakingBtn.frame = CGRect(x: 15, y: height - 125, width: 40, height: 40)
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
        walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 135, width: 60, height: 60)
        // ウォークボタンの背景
        walkButton.backgroundColor = .white
        // ウォークボタンを丸くする
        walkButton.layer.cornerRadius = 60 * 0.5
        walkButton.clipsToBounds = true
        // ウォークボタンタップ時の画像反転を抑制
        walkButton.adjustsImageWhenHighlighted = false
        
        // ウォークスライダーの位置
        walkSlider.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 135, width: 120, height: 60)
        // スライダーラベルの位置
        sliderLabel.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 95, width: 120, height: 20)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // セミモーダルビューを非表示にする
        floatingPanelController.removePanelFromParent(animated: true)
    }
    
    // ウォークボタンが押下された時
    @IBAction func walkButtonTap(_ sender: Any) {

        if latitudeNow == "" || longitudeNow == "" {
            // 起動時の座標を設定
            self.latitudeNow = String((locManager.location?.coordinate.latitude)!)
            self.longitudeNow = String((locManager.location?.coordinate.longitude)!)
        }
        
        print("DBG\(latitudeNow)")
        print("DBG\(longitudeNow)")
        
        UIView.animate(withDuration: 0.1,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseOut,
                       animations: { () -> Void in
                           self.walkButton.transform = CGAffineTransform(scaleX: 1.00, y: 1.00)
                           self.walkButton.alpha = 1.0
                       },
                       completion: nil)
        
        // 現在地の緯度経度をスタートに設定
        coordinatesArray[0]["lat"] = Double(latitudeNow)
        coordinatesArray[0]["lon"] = Double(longitudeNow)
        // 現在地からランダムな位置の緯度経度をゴールに設定
        coordinatesArray[1]["lat"] = Double(latitudeNow)! + Double.random(in: -0.01...0.01)
        coordinatesArray[1]["lon"] = Double(longitudeNow)! + Double.random(in: -0.01...0.01)
        
        // スライダーの段階に応じたラベルを設定する
        switch walkSlider.value {
        case 0:
            // 現在地からランダムな位置の緯度経度をゴールに設定（短距離）
            coordinatesArray[1]["lat"] = Double(latitudeNow)! + Double.random(in: -0.01...0.01)
            coordinatesArray[1]["lon"] = Double(longitudeNow)! + Double.random(in: -0.01...0.01)
            
        case 5:
            // 現在地からランダムな位置の緯度経度をゴールに設定（中距離）
            coordinatesArray[1]["lat"] = Double(latitudeNow)! + Double.random(in: -0.016...0.016)
            coordinatesArray[1]["lon"] = Double(longitudeNow)! + Double.random(in: -0.016...0.016)
            
        case 10:
            // 現在地からランダムな位置の緯度経度をゴールに設定（長距離）
            coordinatesArray[1]["lat"] = Double(latitudeNow)! + Double.random(in: -0.05...0.05)
            coordinatesArray[1]["lon"] = Double(longitudeNow)! + Double.random(in: -0.05...0.05)
            
        default: break
        }
        // HUDを表示
        SVProgressHUD.show(withStatus: "ルート探索中")
        // 地図を作成
        makeMap()
        // HUDを非表示
        SVProgressHUD.dismiss(withDelay: 0.1)
    }
    
    // ボタンが押された時
    @IBAction func walkButtonTapDown(_ sender: Any) {
        if let generator = impactFeedback as? UIImpactFeedbackGenerator {
            generator.impactOccurred()
        }
        
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseOut,
                       animations: { () -> Void in
                           self.walkButton.transform = CGAffineTransform(scaleX: 0.80, y: 0.80)
                           self.walkButton.alpha = 0.7
                       },
                       completion: nil)
    }
    
    // 　ボタン押下がキャンセルされた時
    @IBAction func walkButtonTapOutside(_ sender: Any) {
        UIView.animate(withDuration: 0.1,
                       delay: 0.0,
                       options: UIView.AnimationOptions.curveEaseOut,
                       animations: { () -> Void in
                           self.walkButton.transform = CGAffineTransform(scaleX: 1.00, y: 1.00)
                           self.walkButton.alpha = 1.0
                       },
                       completion: nil)
    }
    
    func makeMap() {
        // マップの表示域を設定
        // マップの中心を配列の一番目に
        let coordinate = CLLocationCoordinate2DMake(coordinatesArray[0]["lat"] as! CLLocationDegrees, coordinatesArray[0]["lon"] as! CLLocationDegrees)
        // マップの範囲
        let span = MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        // 中心と範囲を設定
        let region = MKCoordinateRegion(center: coordinate, span: span)
        // 反映
        mapView.setRegion(region, animated: true)
        
        // 緯度経度値をもつ構造体を生成（ルート用）
        var routeCoordinates: [CLLocationCoordinate2D] = []
        
        // 前回設定したピンを削除する
        mapView.removeAnnotations(annotationArray)
        annotationArray = []
        
        // アノテーションを生成
        var annotation: MKPointAnnotation!
        
        // 配列分繰り返す
        for i in 0..<coordinatesArray.count {
            // アノテーションを生成
            annotation = MKPointAnnotation()
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
        
        // スタート地点とゴール地点の標高差を取得する
        getElevation(startPoint: CLLocationCoordinate2DMake(coordinatesArray[0]["lat"] as! CLLocationDegrees, coordinatesArray[0]["lon"] as! CLLocationDegrees), goalPoint: CLLocationCoordinate2DMake(coordinatesArray[1]["lat"] as! CLLocationDegrees, coordinatesArray[1]["lon"] as! CLLocationDegrees), annotation: annotation)
        
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
                        region.span.latitudeDelta = Double(MKCoordinateRegion(rect).span.latitudeDelta) * 1.6
                        region.span.longitudeDelta = Double(MKCoordinateRegion(rect).span.longitudeDelta) * 1.6
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
                        
                        // 日付の取得
                        let day = Date()
                        // 所要時間を加算
                        let modifiedDate = Calendar.current.date(byAdding: .minute, value: self.time, to: day)!
                        // 到着時刻を設定
                        self.semiModalViewController.infoLabel.text = self.semiModalViewController.infoLabel.text! + "\n" + DateUtils.stringFromDate(date: modifiedDate, format: "HH時mm分") + "到着"
                        
                        // 開始ボタン押下時のセレクター
                        self.semiModalViewController.startButton.addTarget(self, action: #selector(self.pushStartButton), for: .touchDown)
                        // 開始ボタンを表示する
                        self.semiModalViewController.startButton.isHidden = false
                        
                        // サブモーダルの位置に合わせて、各種ボタンの位置を調整する
                        let dispSize: CGSize = UIScreen.main.bounds.size
                        let height = Int(dispSize.height)
                        let width = Int(dispSize.width)
                        
                        // 開始ボタンの位置を調整
                        self.semiModalViewController.startButton.frame = CGRect(x: (width * 4 / 5) - 10, y: 50, width: 60, height: 40)
                        // 終了ボタンの位置を調整
                        self.semiModalViewController.endButton.frame = CGRect(x: (width * 4 / 5) - 10, y: 50, width: 60, height: 40)
                        
                        // 位置情報を最新化する
                        self.semiModalViewController.editLabel()
                        // サブモーダルを更新する
                        self.floatingPanelController.reloadInputViews()
                        // サブモーダルに情報を表示するため、位置をハーフにする
                        self.floatingPanelController.move(to: .half, animated: true)
                                                
                        self.walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 210, width: 60, height: 60)
                        self.trakingBtn.frame = CGRect(x: 15, y: height - 195, width: 40, height: 40)
                        // 　ウォークスライダーの位置
                        self.walkSlider.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 210, width: 120, height: 60)
                        // スライダーラベルの位置
                        self.sliderLabel.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 170, width: 120, height: 20)
                    }
                })
            }
        }
    }
    
    // 標高値の取得
    // 国土地理院「電子国土ポータル」のAPIを使用
    // https://portal.cyberjapan.jp/help/development.html#api
    func getElevation(startPoint: CLLocationCoordinate2D, goalPoint: CLLocationCoordinate2D, annotation: MKPointAnnotation) {
        // 非同期のグループ作成
        let dispatchGroup = DispatchGroup()
        // 非同期実行の準備
        let dispatchQueue = DispatchQueue(label: "queue", attributes: .concurrent)
        
        var startElevation: Double!
        var goalElevation: Double!
        
        // スタート地点の標高取得の非同期処理
        dispatchGroup.enter()
        dispatchQueue.async {
            // 待ち用のセマフォ
            // semaphore = DispatchSemaphore(value: 0)
            // HTTPリクエスト設定
            let add =
                "https://cyberjapandata2.gsi.go.jp/" +
                "general/dem/scripts/getelevation.php" +
                "?lon=\(startPoint.longitude)&lat=\(startPoint.latitude)&outtype=JSON"
            // URLの作成
            let url = URL(string: add)
            // URLリクエストの作成
            let req = URLRequest(url: url! as URL,
                                 cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                                 timeoutInterval: 3.0)
            // サーバ非同期接続
            let res = URLSession.shared.dataTask(with: req) { data, _, _ in
                guard let data = data else { return }
                do {
                    // JSONデータ取得
                    let obj = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    // JSONから標高を取り出す
                    if let unwrapped = obj["elevation"] {
                        // 標高が取得できない地点は、ABENDするのでダウンキャストチェックする
                        if let unwrappedDouble = unwrapped as? Double {
                            startElevation = unwrappedDouble
                        } else {
                            // 取得できなかった時は、標高は999.999にする
                            startElevation = 999.999
                        }
                        self.mapView.addAnnotation(annotation)
                        dispatchGroup.leave()
                    }
                    
                } catch let e {
                    print(e)
                }
                // 待ちセマフォを解除
                // self.semaphore.signal()
            }
            // 非同期通信を開始
            res.resume()
        }
        
        // ゴール地点の標高取得の非同期処理
        dispatchGroup.enter()
        dispatchQueue.async {
            // 待ち用のセマフォ
            // semaphore = DispatchSemaphore(value: 0)
            // HTTPリクエスト設定
            let add =
                "https://cyberjapandata2.gsi.go.jp/" +
                "general/dem/scripts/getelevation.php" +
                "?lon=\(goalPoint.longitude)&lat=\(goalPoint.latitude)&outtype=JSON"
            // URLの作成
            let url = URL(string: add)
            // URLリクエストの作成
            let req = URLRequest(url: url! as URL,
                                 cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                                 timeoutInterval: 3.0)
            // サーバ非同期接続
            let res = URLSession.shared.dataTask(with: req) { data, _, _ in
                guard let data = data else { return }
                do {
                    // JSONデータ取得
                    let obj = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    // JSONから標高を取り出す
                    if let unwrapped = obj["elevation"] {
                        // 標高が取得できない地点は、ABENDするのでダウンキャストチェックする
                        if let unwrappedDouble = unwrapped as? Double {
                            goalElevation = unwrappedDouble
                        } else {
                            // 取得できなかった時は、標高は999.999にする
                            goalElevation = 999.999
                        }
                        self.mapView.addAnnotation(annotation)
                        dispatchGroup.leave()
                    }
                    
                } catch let e {
                    print(e)
                }
                // 待ちセマフォを解除
                // self.semaphore.signal()
            }
            // 非同期通信を開始
            res.resume()
        }
        
        // ２つの非同期処理が完了したら、標高差を求めて設定する
        dispatchGroup.notify(queue: .main) {
            if (startElevation == 999.999) || (goalElevation == 999.999) {
                // 取得できなかった時は、標高差はハイフンにする
                annotation.title = annotation.title! + "\n" + "標高差:-----m"
            } else {
                // スタート地点とゴール地点の標高差を求める（小数点１桁）
                let elevation = String(round((goalElevation - startElevation) * 10) / 10)
                print("DBG標高差\(elevation)")
                // アノテーションに標高を追加する
                annotation.title = annotation.title! + "\n" + "標高差:" + elevation + "m"
            }
        }
        
        return
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        for annotation in mapView.annotations {
            if let userLocation = annotation as? MKUserLocation {
                userLocation.title = "スタート地点（現在地）"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            // pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            // 吹き出しで情報を表示
            pinView?.canShowCallout = true
            // ドラッグを可能に
            pinView?.isDraggable = true
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        if newState == .ending {
            if let pinDrop = view.annotation as? MKPointAnnotation {
                // 現在地からピンをドロップした位置の緯度経度をゴールに設定
                coordinatesArray[1]["lat"] = pinDrop.coordinate.latitude
                coordinatesArray[1]["lon"] = pinDrop.coordinate.longitude
            }
            // HUDを表示
            SVProgressHUD.show(withStatus: "ルート探索中")
            // 地図を作成
            makeMap()
            // HUDを非表示
            SVProgressHUD.dismiss(withDelay: 0.1)
        }
    }
    
    // ピンを繋げている線の幅や色を調整
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let route: MKPolyline = overlay as! MKPolyline
        let routeRenderer = MKPolylineRenderer(polyline: route)
        routeRenderer.strokeColor = UIColor(red: 1.00, green: 0.35, blue: 0.30, alpha: 0.8)
        routeRenderer.lineWidth = 3.0
        return routeRenderer
    }
    
    // ボタン押下時の振動
    private lazy var impactFeedback: Any? = {
        // styleは.light, .medium, heavyの３種類がある
        let generator: UIFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()
    // アラート系の振動
    private lazy var notificationFeedback: Any? = {
        let generator: UIFeedbackGenerator = UINotificationFeedbackGenerator()
        generator.prepare()
        return generator
    }()
    // セレクト系の振動
    private lazy var selectionFeedback: Any? = {
        let generator: UIFeedbackGenerator = UISelectionFeedbackGenerator()
        generator.prepare()
        return generator
    }()
    
    @IBAction func sliderValue(_ sender: Any) {
        // スライダーを３段階にする
        walkSlider.value = round(walkSlider.value / 5) * 5
        
        // マップの中心を配列の一番目に
        let coordinate = CLLocationCoordinate2DMake(Double(latitudeNow)!, Double(longitudeNow)!)
        // マップの範囲
        var span = MKCoordinateSpan(latitudeDelta: 0.016, longitudeDelta: 0.016)
        
        // スライダーの段階に応じたラベルを設定する
        switch walkSlider.value {
        case 0: sliderLabel.text = String("Short-Range")
            // マップの表示域を設定
            // マップの範囲
            span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            
        case 5: sliderLabel.text = String("Mid-Range")
            // マップの表示域を設定
            // マップの範囲
            span = MKCoordinateSpan(latitudeDelta: 0.016, longitudeDelta: 0.016)
            
        case 10: sliderLabel.text = String("Long-Range")
            // マップの表示域を設定
            // マップの範囲
            span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            
        default: break
        }
        // スライドバーを動かした時に振動させる
        if let generator = selectionFeedback as? UISelectionFeedbackGenerator {
            generator.selectionChanged()
        }
        
        // 中心と範囲を設定
        let region = MKCoordinateRegion(center: coordinate, span: span)
        // 反映
        mapView.setRegion(region, animated: true)
    }
    
    
    @objc func pushStartButton(sender: UIButton){
        print("startbutton pushed.")
        
        if let generator = impactFeedback as? UIImpactFeedbackGenerator {
            generator.impactOccurred()
        }
        
        // 終了ボタン押下時のセレクター
        self.semiModalViewController.endButton.addTarget(self, action: #selector(self.pushEndButton), for: .touchDown)
        // 開始ボタンが押されたら、終了ボタンを表示
        self.semiModalViewController.endButton.isHidden = false
        // 開始ボタンを非表示
        self.semiModalViewController.startButton.isHidden = true
        // ウォークボタンを非表示
        walkButton.isHidden = true
        
        // サブモーダルの情報を非表示とするため、位置をチップにする
        self.floatingPanelController.move(to: .tip, animated: true)
        
        let dispSize: CGSize = UIScreen.main.bounds.size
        let height = Int(dispSize.height)
        let width = Int(dispSize.width)
        
        // ボタンの位置をtipに調整する
        walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 135, width: 60, height: 60)
        trakingBtn.frame = CGRect(x: 15, y: height - 125, width: 40, height: 40)
        // ウォークスライダーの位置
        walkSlider.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 135, width: 120, height: 60)
        // スライダーラベルの位置
        sliderLabel.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 95, width: 120, height: 20)
        
        // 開始ボタンの位置を調整
        self.semiModalViewController.startButton.frame = CGRect(x: (width * 4 / 5) - 10, y: 15, width: 60, height: 40)
        // 終了ボタンの位置を調整
        self.semiModalViewController.endButton.frame = CGRect(x: (width * 4 / 5) - 10, y: 15, width: 60, height: 40)
        // サブモーダルを更新する
        self.floatingPanelController.reloadInputViews()
        
        
    }
    
    
    @objc func pushEndButton(sender: UIButton){
        print("endbutton pushed.")
        
        if let generator = impactFeedback as? UIImpactFeedbackGenerator {
            generator.impactOccurred()
        }
        
        // 終了ボタンが押されたら、終了ボタンを非表示
        self.semiModalViewController.endButton.isHidden = true
        // ウォークボタンを表示
        walkButton.isHidden = false
        
        // 前回設定したピンを削除する
        mapView.removeAnnotations(annotationArray)
        annotationArray = []
        // 前回表示したオーバーレイを削除する
        mapView.removeOverlays(overlayArray)
        overlayArray = []
                
        // ラベル変数のテキストを更新する（初期化）
        self.semiModalViewController.hosuLabel.text = ""
        self.semiModalViewController.infoLabel.text = ""
                
        // 位置情報を最新化する（初期化）
        self.semiModalViewController.editLabel()
        // サブモーダルを更新する
        self.floatingPanelController.reloadInputViews()
        // サブモーダルの情報を非表示とするため、位置をチップにする
        self.floatingPanelController.move(to: .tip, animated: true)
        
        let dispSize: CGSize = UIScreen.main.bounds.size
        let height = Int(dispSize.height)
        let width = Int(dispSize.width)
        
        // ボタンの位置をtipに調整する
        walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 135, width: 60, height: 60)
        trakingBtn.frame = CGRect(x: 15, y: height - 125, width: 40, height: 40)
        // ウォークスライダーの位置
        walkSlider.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 135, width: 120, height: 60)
        // スライダーラベルの位置
        sliderLabel.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 95, width: 120, height: 20)
        
        // スライダーの値を初期値とする
        walkSlider.value = 5
        sliderLabel.text = String("Mid-Range")
        
        // マップの中心を配列の一番目に
        let coordinate = CLLocationCoordinate2DMake(Double(latitudeNow)!, Double(longitudeNow)!)
        // マップの範囲
        let span = MKCoordinateSpan(latitudeDelta: 0.016, longitudeDelta: 0.016)
        // 中心と範囲を設定
        let region = MKCoordinateRegion(center: coordinate, span: span)
        // 反映
        mapView.setRegion(region, animated: true)
        
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
            walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 135, width: 60, height: 60)
            trakingBtn.frame = CGRect(x: 15, y: height - 125, width: 40, height: 40)
            // 　ウォークスライダーの位置
            walkSlider.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 135, width: 120, height: 60)
            // スライダーラベルの位置
            sliderLabel.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 95, width: 120, height: 20)
            // 開始ボタンの位置を調整
            self.semiModalViewController.startButton.frame = CGRect(x: (width * 4 / 5) - 10, y: 15, width: 60, height: 40)
            // 終了ボタンの位置を調整
            self.semiModalViewController.endButton.frame = CGRect(x: (width * 4 / 5) - 10, y: 15, width: 60, height: 40)
            // サブモーダルを更新する
            self.floatingPanelController.reloadInputViews()
            
        case .half:
            print("half")
            // ボタンの位置をhalfに調整する
            walkButton.frame = CGRect(x: (width / 2) - 30, y: height - 210, width: 60, height: 60)
            trakingBtn.frame = CGRect(x: 15, y: height - 195, width: 40, height: 40)
            // 　ウォークスライダーの位置
            walkSlider.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 210, width: 120, height: 60)
            // スライダーラベルの位置
            sliderLabel.frame = CGRect(x: (width * 3 / 4) - 40, y: height - 170, width: 120, height: 20)
            // 開始ボタンの位置を調整
            self.semiModalViewController.startButton.frame = CGRect(x: (width * 4 / 5) - 10, y: 50, width: 60, height: 40)
            // 終了ボタンの位置を調整
            self.semiModalViewController.endButton.frame = CGRect(x: (width * 4 / 5) - 10, y: 50, width: 60, height: 40)
            // サブモーダルを更新する
            self.floatingPanelController.reloadInputViews()
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
        case .tip: return 35.0
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
class DateUtils {
    class func dateFromString(string: String, format: String) -> Date {
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter.date(from: string)!
    }

    class func stringFromDate(date: Date, format: String) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
