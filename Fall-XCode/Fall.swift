
import SwiftUI
import Firebase
import FirebaseFunctions

// Appdelegate responsible for handling app lifecycle events
class AppDelegate: NSObject, UIApplicationDelegate {
    //called when application finihes launching
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure() //initialises firebase
    return true
  }
}


// main entry point
@main
struct mmApp: App {
    // state object to manage fall detection logiv
    @StateObject var viewModel = FallDetectionViewModel()
    //coredata database handling
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                SignUpView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environment(\.font, .custom("Helvetica", size: 14))
            }
            .environmentObject(viewModel)
        }
    }
}
