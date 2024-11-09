import UIKit
import Flutter
import GoogleMaps
import Firebase
import UserNotifications 

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAEhRGkjRnPgfTO4ujnw3q0VNv1fnzvYR8")
    FirebaseApp.configure()
    // Request permission for notifications
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      // Handle permission errors if needed
      if let error = error {
        print("Error requesting notification permission: \(error.localizedDescription)")
      }
    }
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  // Handle receiving a notification while the app is in the foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Show the notification alert and play a sound
    completionHandler([.alert, .sound])
  }

  // Handle the notification response
  func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              didReceive response: UNNotificationResponse, 
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    // Handle the notification action here
    completionHandler()
  }
}
