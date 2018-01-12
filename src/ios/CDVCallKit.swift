/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */
import UIKit

@available(iOS 10.0, *)
@objc(CDVCallKit) class CDVCallKit : CDVPlugin {
    var callbackId: String?
    private var _callManager: AnyObject?
    private var _providerDelegate: AnyObject?
    
    @available(iOS 10.0, *)
    var callManager: CDVCallManager? {
        get {
            return _callManager as? CDVCallManager
        }
        set {
            _callManager = newValue
        }
    }
    
    @available(iOS 10.0, *)
    var providerDelegate: CDVProviderDelegate? {
        get {
            return _providerDelegate as? CDVProviderDelegate
        }
        set {
            _providerDelegate = newValue
        }
    }
    
    @available(iOS 10.0, *)
    @objc func register(_ command:CDVInvokedUrlCommand) {
        self.commandDelegate.run(inBackground: {
            var pluginResult = CDVPluginResult(
                status : CDVCommandStatus_ERROR
            )
            
            self.callManager = CDVCallManager()
            
            self.providerDelegate = CDVProviderDelegate(callManager: self.callManager!)
            
            self.callbackId = command.callbackId
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.handle(withNotification:)), name: Notification.Name("CDVCallKitCallsChangedNotification"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.handle(withNotification:)), name: Notification.Name("CDVCallKitAudioNotification"), object: nil)
            
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK
            )
            pluginResult?.setKeepCallbackAs(true)
            
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
        });
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func reportIncomingCall(_ command:CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status : CDVCommandStatus_ERROR
        )
        
        let uuid = UUID()
        let name = command.arguments[0] as? String ?? ""
        let hasVideo = command.arguments[1] as? Bool ?? false
        let supportsGroup = command.arguments[2] as? Bool ?? false
        let supportsUngroup = command.arguments[3] as? Bool ?? false
        let supportsDTMF = command.arguments[4] as? Bool ?? false
        let supportsHold = command.arguments[5] as? Bool ?? false
        
        // // iOS 9: if the application is in background, show a notification
        // let localNotification = UILocalNotification()
        // localNotification.fireDate = NSDate(timeIntervalSinceNow: 1) as Date
        // localNotification.alertBody = name
        // UIApplication.shared.scheduleLocalNotification(localNotification)
        
        
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: hasVideo ? "Incoming Video Call" : "Incoming Call", arguments: nil)
        content.body = name
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "INCOMING_CALL"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "call" + uuid.uuidString, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
        
        
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs : uuid.uuidString
        )
        pluginResult?.setKeepCallbackAs(false)
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
    
    @objc func askNotificationPermission(_ command:CDVInvokedUrlCommand) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
        }
    }
    
    @available(iOS 10.0, *)
    func startCall(_ command:CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status : CDVCommandStatus_ERROR
        )
        
        let name = command.arguments[0] as? String ?? ""
        let isVideo = (command.arguments[1] as! Bool)
        
        let uuid = UUID()
        self.callManager?.startCall(uuid, handle: name, video: isVideo)
        
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs : uuid.uuidString
        )
        pluginResult?.setKeepCallbackAs(false)
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
    
    func finishRing(_ command:CDVInvokedUrlCommand) {
        let pluginResult = CDVPluginResult(
            status : CDVCommandStatus_OK
        )
        
        pluginResult?.setKeepCallbackAs(false)
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
        /* does nothing on iOS */
    }
    
    @available(iOS 10.0, *)
    @objc func endCall(_ command:CDVInvokedUrlCommand) {
        self.commandDelegate.run(inBackground: {
            let uuid = UUID(uuidString: command.arguments[0] as? String ?? "")
            
            if (uuid != nil) {
                let call = self.callManager?.callWithUUID(uuid!)
                
                if (call != nil) {
                    self.callManager?.end(call!)
                }
            }
            if (uuid != nil) {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["call" + uuid!.uuidString])
            }
        });
    }
    
    @available(iOS 10.0, *)
    func callConnected(_ command:CDVInvokedUrlCommand) {
        self.commandDelegate.run(inBackground: {
            let uuid = UUID(uuidString: command.arguments[0] as? String ?? "")
            
            if (uuid != nil) {
                let call = self.callManager?.callWithUUID(uuid!)
                
                if (call != nil) {
                    call?.connectedCDVCall()
                }
            }
            if (uuid != nil) {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["call" + uuid!.uuidString])
            }
        });
    }
    
    @available(iOS 10.0, *)
    @objc func handle(withNotification notification : NSNotification) {
        if (notification.name == Notification.Name("CDVCallKitCallsChangedNotification")) {
            let notificationObject = notification.object as? CDVCallManager
            var resultMessage = [String: Any]()
            
            if (((notificationObject?.calls) != nil) && (notificationObject!.calls.count>0)) {
                let call = (notificationObject?.calls[0])! as CDVCall
                
                resultMessage = [
                    "callbackType" : "callChanged",
                    "uuid" : call.uuid.uuidString as String? ?? "",
                    "handle" : call.handle as String? ?? "",
                    "isOutgoing" : call.isOutgoing as Bool,
                    "isOnHold" : call.isOnHold as Bool,
                    "hasConnected" : call.hasConnected as Bool,
                    "hasEnded" : call.hasEnded as Bool,
                    "hasStartedConnecting" : call.hasStartedConnecting as Bool,
                    "endDate" : call.endDate?.string("yyyy-MM-dd'T'HH:mm:ssZ") as String? ?? "",
                    "connectDate" : call.connectDate?.string("yyyy-MM-dd'T'HH:mm:ssZ") as String? ?? "",
                    "connectingDate" : call.connectingDate?.string("yyyy-MM-dd'T'HH:mm:ssZ") as String? ?? "",
                    "duration" : call.duration as Double
                ]
            }
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: resultMessage)
            pluginResult?.setKeepCallbackAs(true)
            
            print("RECEIVED CALL CHANGED NOTIFICATION: \(notification)")
            
            self.commandDelegate!.send(
                pluginResult, callbackId: self.callbackId
            )
        } else if (notification.name == Notification.Name("CDVCallKitAudioNotification")) {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [ "callbackType" : "audioSystem", "message" : notification.object as? String ?? "" ])
            pluginResult?.setKeepCallbackAs(true)
            
            self.commandDelegate!.send(
                pluginResult, callbackId: self.callbackId
            )
            
            print("RECEIVED AUDIO NOTIFICATION: \(notification)")
        } else {
            print("INVALID NOTIFICATION RECEIVED: \(notification)")
        }
    }
    
    @objc func receive(_ notification: Notification) {
        if(notification.name == Notification.Name("AppNotificationAction")) {
            let userInfo = notification.userInfo
            let response = userInfo?["notification"] as? UNNotificationResponse
            if (response?.notification.request.content.categoryIdentifier == "INCOMING_CALL") {
                if (response?.actionIdentifier == "ACCEPT_ACTION") {
                    let resultMessage = [
                        "callbackType": "callAccept",
                        "uuid": String(describing: response?.notification.request.identifier.dropFirst(4))
                    ]
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: resultMessage)
                    pluginResult?.setKeepCallbackAs(true)
                    
                    print("RECEIVED CALL ACCEPT COMMAND")
                    
                    self.commandDelegate!.send(
                        pluginResult, callbackId: self.callbackId
                    )
                    let acceptCommand = CDVInvokedUrlCommand.init(arguments: [response?.notification.request.identifier], callbackId: nil, className: nil, methodName: nil)!
                    self.callConnected(acceptCommand)
                }
                else if (response?.actionIdentifier == "DECLINE_ACTION") {
                    let resultMessage = [
                        "callbackType": "callDecline",
                        "uuid": String(describing: response?.notification.request.identifier.dropFirst(4))
                    ]
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: resultMessage)
                    pluginResult?.setKeepCallbackAs(true)
                    
                    print("RECEIVED CALL DECLINE COMMAND")
                    
                    self.commandDelegate!.send(
                        pluginResult, callbackId: self.callbackId
                    )
                    let declineCommand = CDVInvokedUrlCommand.init(arguments: [response?.notification.request.identifier], callbackId: nil, className: nil, methodName: nil)!
                    self.endCall(declineCommand)
                }
                else if (response?.actionIdentifier == UNNotificationDismissActionIdentifier) {
                    let resultMessage = [
                        "callbackType": "callDismiss",
                        "uuid": String(describing: response?.notification.request.identifier.dropFirst(4))
                    ]
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: resultMessage)
                    pluginResult?.setKeepCallbackAs(true)
                    
                    print("RECEIVED CALL DISMISS COMMAND")
                    
                    self.commandDelegate!.send(
                        pluginResult, callbackId: self.callbackId
                    )
                    let declineCommand = CDVInvokedUrlCommand.init(arguments: [response?.notification.request.identifier], callbackId: nil, className: nil, methodName: nil)!
                    self.endCall(declineCommand)
                }
                else if (response?.actionIdentifier == UNNotificationDefaultActionIdentifier) {
                    let resultMessage = [
                        "callbackType": "callOpen",
                        "uuid": String(describing: response?.notification.request.identifier.dropFirst(4))
                    ]
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: resultMessage)
                    pluginResult?.setKeepCallbackAs(true)
                    
                    print("RECEIVED CALL OPEN COMMAND")
                    
                    self.commandDelegate!.send(
                        pluginResult, callbackId: self.callbackId
                    )
                    let acceptCommand = CDVInvokedUrlCommand.init(arguments: [response?.notification.request.identifier], callbackId: nil, className: nil, methodName: nil)!
                    self.callConnected(acceptCommand)
                }
            }
            
        }
    }
    
    @objc override func pluginInitialize() {        
        let acceptAction = UNNotificationAction(identifier: "ACCEPT_ACTION",
                                                title: "Accept",
                                                options: [.foreground])
        let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION",
                                                 title: "Decline",
                                                 options: [.destructive,.foreground])
        
        let callCategory = UNNotificationCategory(identifier: "INCOMING_CALL",
                                                  actions: [acceptAction, declineAction],
                                                  intentIdentifiers: [],
                                                  options: [.customDismissAction])
        
        // Register the notification categories.
        UNUserNotificationCenter.current().add(callCategory)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.receive(_:)), name: NSNotification.Name("AppNotificationAction"), object: nil)
    }
}
