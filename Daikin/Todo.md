# Todo iOS and shared
- error handling without popups?
- consumption chart
    3.) show data with bar charts
        - Source Will Dale --> new folder OR as module
- code clean up
- shortcuts (intents?)
- udpate AC data in ACView (onAppear is *not* called always when coming from homescreen)  
- iPad: network problems when aircon is selected via widget (maybe already solved with StackNavigationViewStyle?) 
- await in refreshable
- implement automatically reload intervall?
- broadcast
- why is ACList.init() called multiple times?

# Todo macOS
- only 1 app instance/window
- app icon is too big in dock and edges are not rounded
- settings look ugly on macOS, use #if os(macOS) Settings { ... }

# Todo Widget
- macOS version?
- goals?
    - select aircon in widget --> open selected aircon in app
    - on / off intent (with selection)


## Done
- outside temperature in ACView 
- ACList: color for modes cold=blue, warm=red 
- settings
- stop spinner on error/timeout
- View ACList
- special strong
- background temp blue/red
- special streamer
- widgets
- icons
- fetch temp
- fan direction
- iPad: select first when in split view (solved with StackNavigationViewStyle)
- iPad: close nav list when aircon is selected (solved with StackNavigationViewStyle)
- delete aircon in settings does not work (works with 2 finger swipe)
- consumption chart
    1.) read comsumption data (done)
    2.) show data as numbers/text (done)
   


# config notes
- Daikin--iOS--Info.plist
    - App Transport Security Settings
        - Allow Arbitrary Loads YES
    - Application Scene Manifest
        - Enable Multiple Windows NO
- macOS.entitlements
    - App Sandbox NO
- widgets
    - target Daikin (iOS) and Widget iOSExtension:
        - Signing & Capabilities -> App Group "group.de.snugdev.daikinwidget"
        - this adds App Group to "Widget iOSExtension.entitlements" and "Daikin (iOS).entitlements"
        - must be same String as UserSettings.appGroup
    
