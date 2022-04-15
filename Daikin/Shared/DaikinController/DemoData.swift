//
//  DemoData.swift
//  Daikin
//
//  Created by Lothar Heinrich on 15.04.22.
//

import Foundation

public func getDemoDataResponse(fakeIp: String, endpoint: String) -> String {
    return demoData[fakeIp + endpoint]!
}



private let demoData = [
    "DEMO0/aircon/get_sensor_info": "ret=OK,htemp=22.5,hhum=40,otemp=8.0,err=0,cmpfreq=0",
    "DEMO1/aircon/get_sensor_info": "ret=OK,htemp=21.0,hhum=45,otemp=8.0,err=0,cmpfreq=0",
    "DEMO2/aircon/get_sensor_info": "ret=OK,htemp=23.0,hhum=35,otemp=8.0,err=0,cmpfreq=0",
    
    "DEMO0/common/basic_info": "ret=OK,type=aircon,reg=eu,dst=1,ver=1_14_48,rev=84B684C,pow=1,err=0,location=0,name=Living%20Room,icon=0,method=polling,port=30050,id=1234-1234-1234-1234-1234,pw=,lpw_flag=0,adp_kind=3,pv=3.30,cpv=3,cpv_minor=20,led=1,en_setzone=1,mac=C0E434E5F2D3,adp_mode=run,en_hol=0,ssid1=Wifi,radio1=-39,ssid=DaikinAP123,grp_name=,en_grp=0",
    
    "DEMO1/common/basic_info": "ret=OK,type=aircon,reg=eu,dst=1,ver=1_14_48,rev=84B684C,pow=0,err=0,location=0,name=Sleeping%20Room,icon=0,method=polling,port=30050,id=1234-1234-1234-1234-1234,pw=,lpw_flag=0,adp_kind=3,pv=3.30,cpv=3,cpv_minor=20,led=1,en_setzone=1,mac=C0E434E5F2D3,adp_mode=run,en_hol=0,ssid1=Wifi,radio1=-39,ssid=DaikinAP123,grp_name=,en_grp=0",
    
    "DEMO2/common/basic_info": "ret=OK,type=aircon,reg=eu,dst=1,ver=1_14_48,rev=84B684C,pow=0,err=0,location=0,name=Kitchen,icon=0,method=polling,port=30050,id=1234-1234-1234-1234-1234,pw=,lpw_flag=0,adp_kind=3,pv=3.30,cpv=3,cpv_minor=20,led=1,en_setzone=1,mac=C0E434E5F2D3,adp_mode=run,en_hol=0,ssid1=Wifi,radio1=-39,ssid=DaikinAP123,grp_name=,en_grp=0",
    
    
    "DEMO0/aircon/get_control_info":
        "ret=OK,pow=0,mode=3,adv=,stemp=20.0,shum=0,dt1=20.0,dt2=M,dt3=21.5,dt4=25.0,dt5=25.0,dt7=25.0,dh1=0,dh2=0,dh3=0,dh4=0,dh5=0,dh7=0,dhh=50,b_mode=4,b_stemp=20.0,b_shum=0,alert=255,f_rate=B,f_dir=0,b_f_rate=B,b_f_dir=0,dfr1=B,dfr2=3,dfr3=3,dfr4=B,dfr5=B,dfr6=5,dfr7=B,dfrh=5,dfd1=0,dfd2=0,dfd3=0,dfd4=0,dfd5=0,dfd6=0,dfd7=0,dfdh=0,dmnd_run=0,en_demand=0",

    "DEMO1/aircon/get_control_info":
        "ret=OK,pow=1,mode=3,adv=,stemp=20.0,shum=0,dt1=20.0,dt2=M,dt3=21.5,dt4=25.0,dt5=25.0,dt7=25.0,dh1=0,dh2=0,dh3=0,dh4=0,dh5=0,dh7=0,dhh=50,b_mode=4,b_stemp=20.0,b_shum=0,alert=255,f_rate=B,f_dir=0,b_f_rate=B,b_f_dir=0,dfr1=B,dfr2=3,dfr3=3,dfr4=B,dfr5=B,dfr6=5,dfr7=B,dfrh=5,dfd1=0,dfd2=0,dfd3=0,dfd4=0,dfd5=0,dfd6=0,dfd7=0,dfdh=0,dmnd_run=0,en_demand=0",

    "DEMO2/aircon/get_control_info":
        "ret=OK,pow=0,mode=4,adv=,stemp=25.0,shum=0,dt1=25.0,dt2=M,dt3=21.5,dt4=25.0,dt5=25.0,dt7=25.0,dh1=0,dh2=0,dh3=0,dh4=0,dh5=0,dh7=0,dhh=50,b_mode=4,b_stemp=25.0,b_shum=0,alert=255,f_rate=B,f_dir=0,b_f_rate=B,b_f_dir=0,dfr1=B,dfr2=3,dfr3=3,dfr4=B,dfr5=B,dfr6=5,dfr7=B,dfrh=5,dfd1=0,dfd2=0,dfd3=0,dfd4=0,dfd5=0,dfd6=0,dfd7=0,dfdh=0,dmnd_run=0,en_demand=0",

]
