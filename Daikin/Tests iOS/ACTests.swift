//
//  ACTests.swift
//  Tests iOS
//
//  Created by Lothar Heinrich on 04.12.21.
//

import XCTest
@testable import Daikin

let responseString_basicInfo = "ret=OK,type=aircon,reg=eu,dst=1,ver=1_14_48,rev=84B684C,pow=0,err=0,location=0,name=%57%6f%68%6e%7a%69%6d%6d%65%72,icon=0,method=polling,port=30050,id=1234-1234-1234-1234-1234,pw=,lpw_flag=0,adp_kind=3,pv=3.30,cpv=3,cpv_minor=20,led=1,en_setzone=1,mac=C0E434E5F2D3,adp_mode=run,en_hol=0,ssid1=Wifi,radio1=-39,ssid=DaikinAP123,grp_name=,en_grp=0"

let responseString_sensorInfo = "ret=OK,htemp=23.0,hhum=45,otemp=8.0,err=0,cmpfreq=0"


class ACTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    func testBasicInfoFromResponse() throws {
        
        let basicInfo = try! BasicInfo(from: responseString_basicInfo)
        
        XCTAssertEqual(basicInfo.name, "%57%6f%68%6e%7a%69%6d%6d%65%72")
        XCTAssertEqual(basicInfo.nameReadable, "Wohnzimmer")
    }
    func testSensorInfoFromResponse() throws {
        
        let sensorInfo = try! SensorInfo(from: responseString_sensorInfo)
        
        XCTAssertEqual(sensorInfo.htemp , Temperature(from: 23.0))
        XCTAssertEqual(sensorInfo.hhum , 45)
        XCTAssertEqual(sensorInfo.otemp , Temperature(from: 8.0))
        
    }
}
