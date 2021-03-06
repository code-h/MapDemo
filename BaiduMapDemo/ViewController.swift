//
//  ViewController.swift
//  BaiduDemo
//
//  Created by marquis on 16/4/22.
//  Copyright © 2016年 marquis. All rights reserved.
//

import UIKit
import SwiftyJSON

class ViewController: UIViewController, BMKMapViewDelegate, BMKLocationServiceDelegate {
    
    var _mapView: BMKMapView?
    var pointAnnotation: BMKPointAnnotation!
    
    //离线地图
    var offlineMap: BMKOfflineMap!
    //本地下载的离线地图
    var localDownloadMapInfo: [BMKOLUpdateElement]!
    
    //定位服务
    var locationService: BMKLocationService!
    //当前用户位置
    var userLocation: BMKUserLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //初始化离线地图服务
        offlineMap = BMKOfflineMap()
        //将Macau数据copy到App的Documents/vmp
        let fileManager = NSFileManager.defaultManager()
        let exsit  = fileManager.fileExistsAtPath(mapDataPath)
        if exsit == false {
            let mapPath = NSBundle.mainBundle().pathForResource("map_data", ofType: "zip")!
            //将地图数据包解压到App的Documents/vmp
            SSZipArchive.unzipFileAtPath(mapPath, toDestination: documentPath.last!)
        }
        //初始化地图
        _mapView = BMKMapView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        _mapView!.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(_mapView!)
        //获取在本地的离线数据包
        let localMapInfo = offlineMap.getUpdateInfo(macaoCode)
        _mapView?.setCenterCoordinate(localMapInfo.pt, animated: true)
        //澳門的經緯度
        let coor = CLLocationCoordinate2DMake(macaoCenter["lat"]!, macaoCenter["lng"]!)
        _mapView!.removeOverlays(_mapView!.overlays)
        
        self.addPointAnnotation()
        //設置顯示範圍
        self.mapDisplayRange(coor, latitudeDelta: rangeDelta["lat"]!, longitudeDelta: rangeDelta["lng"]!)
        
        //添加定位
        //定位功能初始化
        locationService = BMKLocationService()
        //設置定位精度
        locationService.desiredAccuracy = kCLLocationAccuracyBest
        //指定最小距離更新（米）
        locationService.distanceFilter = 10
        locationService.startUserLocationService()
        self.followLocation()
    }
    
    //添加标注
    func addPointAnnotation(){
        var coor: CLLocationCoordinate2D = CLLocationCoordinate2D.init()
        let data = self.changeData()
        for i in 0..<data.count {
            pointAnnotation = BMKPointAnnotation.init()
            coor.longitude = data[i]["lng"].doubleValue
            coor.latitude = data[i]["lat"].doubleValue
            
            pointAnnotation.coordinate = coor
            pointAnnotation.title = data[i]["title"].stringValue
            pointAnnotation.subtitle = data[i]["subtitle"].stringValue
            
            _mapView?.addAnnotation(pointAnnotation)
        }
    }
    
    //数据转换
    func changeData() -> JSON {
        let path = NSBundle.mainBundle().pathForResource("Locations", ofType: "json")
        let jsonData = NSData(contentsOfFile: path!)
        let json = JSON(data: jsonData!)
        
        return json
    }
    
    //根据anntation生成对应的View
    func mapView(mapView: BMKMapView!, viewForAnnotation annotation: BMKAnnotation!) -> BMKAnnotationView! {
        //普通标注
        if annotation as! BMKPointAnnotation == pointAnnotation {
            let AnnotationViewID = "renameMark"
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(AnnotationViewID) as! BMKPinAnnotationView?
            if annotationView == nil {
                annotationView = BMKPinAnnotationView(annotation: annotation, reuseIdentifier: AnnotationViewID)
                //设置颜色
                annotationView!.pinColor = UInt(BMKPinAnnotationColorPurple)
                //从天上掉下的动画
                annotationView!.animatesDrop = true
                //设置可拖曳
                annotationView!.draggable = false
            }
            return annotationView
        }
        return nil
    }
    
    //设置地图显示范围(其他地方不会显示)
    func mapDisplayRange(center:CLLocationCoordinate2D, latitudeDelta:Double, longitudeDelta:Double) {
        let span = BMKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        _mapView?.rotateEnabled = false//禁用旋转手势
        _mapView?.limitMapRegion = BMKCoordinateRegionMake(center, span)
    }
    
    func followLocation() {
        //进入普通定位
        _mapView!.showsUserLocation = false
        _mapView!.userTrackingMode = locationModel["None"]!
        _mapView!.showsUserLocation = true
        _mapView!.scrollEnabled = true  //允許用户移动地图
        _mapView!.updateLocationData(userLocation)
    }
    
    //用户位置更新后，会调用此函数
    func didUpdateBMKUserLocation(userLocation: BMKUserLocation!) {
        _mapView!.updateLocationData(userLocation)
        print("目前位置：\(userLocation.location.coordinate.longitude), \(userLocation.location.coordinate.latitude)")
    }
    
    //用户方向更新后，会调用此函数
    func didUpdateUserHeading(userLocation: BMKUserLocation!) {
        _mapView!.updateLocationData(userLocation)
        print("目前朝向：\(userLocation.heading)")
    }
    
    func didFailToLocateUserWithError(error: NSError!) {
        NSLog("定位失敗")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        _mapView?.viewWillAppear()
        _mapView?.delegate = self //此处记得不用的时候需要置nil，否则影响内存的释放
        locationService.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        _mapView?.viewWillDisappear()
        _mapView?.delegate = nil //不用时，置nil
        locationService.delegate = nil
    }
    
}

