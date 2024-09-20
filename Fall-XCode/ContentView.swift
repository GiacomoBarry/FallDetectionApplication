//Importing Libraries
import SwiftUI
import CoreMotion
import TensorFlowLite
import Foundation
import Charts
import UserNotifications
import CoreLocation
import AudioToolbox
import Firebase
import FirebaseFunctions


//My Apps main Page


struct ContentView: View {
    //Initliasing motion and location managers for sensor data
    let motionManager = CMMotionManager()
    let locationManager = CLLocationManager()
    //State variables for handling chart data and detection flags
    @State private var chartDataX: [Double] = []
    @State private var chartDataY: [Double] = []
    @State private var chartDataZ: [Double] = []
    @State private var accelerationDataBuffer: [[Double]] = []
    @State private var previousSpeed: Double = 0.0
    @State private var fallDetected: Bool = false
    //sharing data between my setting and main conten view
    @EnvironmentObject var viewModel: FallDetectionViewModel
    @State private var interpreter: Interpreter?
  
    //constants defining limits for data collection and processing
    private let dataLimit = 50
    private let timeWindow: Int = 10
    private let mylocationManager = LocationManager.shared
    
//defines content and layout
    
    var body: some View {
        NavigationView {
            
            ZStack{
                Color("PrimaryColour").edgesIgnoringSafeArea(.all)
                
                VStack (spacing:20){
                    
                    Image(systemName: "house.circle.fill")
                        .foregroundColor(Color("SecondaryColour"))
                        .frame(width: 50.0, height: 50.0)
                        .shadow(radius: 20)
                        .imageScale(/*@START_MENU_TOKEN@*/.large/*@END_MENU_TOKEN@*/)
                        .font(.largeTitle)
                        .padding(.top,20)
                    
                    Spacer()
                    VStack(spacing: 15){
                        Text(fallDetected ? "Fall Detected!" : "You are OK")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(fallDetected ? .red : Color("SecondaryColour"))
                        .padding()
                        .background(fallDetected ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        
                        if fallDetected {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.red)
                                                .font(.largeTitle)
                                                .padding(.top, 180)
                                        } else {
                                            Image(systemName: "hand.thumbsup.fill")
                                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.green]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .font(.largeTitle)
                                                .padding(.top, 180)
                                        }
                                    
                        
                 
                        
                        NavigationLink("Settings", destination: SettingsView())
                                                    .font(.headline)
                                                    .bold()
                                                    .padding()
                                                    .foregroundColor(.white)
                                                    .background(Color("SecondaryColour"))
                                                    .cornerRadius(14)
                                                    .shadow(radius: 2)
                        
                    
                        
                    }
                }
                .onAppear {
                    setupEnvironment() //setup initial configurations when the view appears
                }
               
            }
        }
                 
    .onChange(of: viewModel.triggerFallDetection) { triggered in
                    if triggered {
                        manuallyTriggerFallDetected()
                        viewModel.triggerFallDetection = false // Reset the trigger
                    }
                }
            }
    
    //prepares app environment by requesting permission and starting sensors
            
    func setupEnvironment(){
    requestNotificationPermission()
    requestLocationPermission()
    interpreter = loadModel()
    startAccelerometer()
                }
    
    //triggers fal detection manually and handles notifications
            
    func manuallyTriggerFallDetected() {
        DispatchQueue.main.async {
            self.fallDetected = true
            self.sendFallNotification()
        }
    }
    
    // USER NOTIFICATION HANDLING
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification Permission Granted")
            } else if let error = error {
                print("Notification permission denied because: \(error.localizedDescription).")
            }
        }
    }
    
    //sending notifications and sms
    func handleFallDetected() {
        DispatchQueue.main.async {
            self.fallDetected=true
            self.sendFallNotification()
            let emergencyNumber = UserDefaults.standard.string(forKey: "emergencyContact") ?? "DefaultEmergencyNumber"
                    self.sendSMSToEmergencyContact(phoneNumber: emergencyNumber, message: "Fall detected at \(Date())! Please check on me.")
        }
    }
    

    
    func vibratePhone() {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    //send notification about the fall
    func sendFallNotification(){
        
        let emergencyNumber = UserDefaults.standard.string(forKey: "emergencyContact") ?? "DefaultEmergencyNumber"
        
        let content = UNMutableNotificationContent()
        content.title = "Fall Detected!"
        content.body = "Sending emergency SMS to \(emergencyNumber). Are you OK?"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request){ error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
        
        sendSMSToEmergencyContact(phoneNumber: emergencyNumber, message: "I Have fallen, Please check on me.")
        
        vibratePhone()
        
    }
    //Request location permission for using GPS data
    
    func requestLocationPermission(){
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    
    //send sms to emergency contact
    func sendSMSToEmergencyContact(phoneNumber: String, message: String) {
        guard let location = LocationManager.shared.lastKnownLocation else {
                print("Location data is not available.")
                return
            }
        
        let locationMessage = "\(message) Location: Latitude \(location.coordinate.latitude), Longitude \(location.coordinate.longitude)."
        
        
        let functions = Functions.functions()
        functions.httpsCallable("sendEmergencySMS").call(["phoneNumber": phoneNumber, "message": locationMessage]) { result, error in
            if let error = error {
                print("Error calling function: \(error.localizedDescription)")
            } else if let resultData = result?.data as? [String: Any], let messageSID = resultData["sid"] as? String {
                print("Message SID: \(messageSID)")
            }
        }
    }
    
    
    // APP LOGIC
    
    // TFLITE MODEL LOADING
    func loadModel() -> Interpreter? {
        guard let modelPath = Bundle.main.path(forResource: "fall_detection_model", ofType: "tflite") else {
            print("Failed to find model")
            return nil
        }
        do {
            let interpreter = try Interpreter(modelPath: modelPath)
            print("Successfully loaded the fall detection model")
            return interpreter
        } catch {
            print("Error loading model: \(error)")
            return nil
        }
    }
    
    // ACCELEROMETER DATA
    func startAccelerometer() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                guard let data = data else { return }
                
                let newAccelerationData = [data.acceleration.x, data.acceleration.y, data.acceleration.z]
                self.updateDataBuffer(with: newAccelerationData)
                // Only call runInference when there are enough data points
                if self.accelerationDataBuffer.count >= self.timeWindow {
                    self.runInference()
                }
                
                // Run inference every time new data is received
                self.runInference()
                
                if locationManager.location?.speed != nil{
                    previousSpeed = locationManager.location?.speed ?? 0.0
                }
            }
        }
    }
    //update data buffer
    func updateDataBuffer(with newAccelerationData : [Double]){
        accelerationDataBuffer.append(newAccelerationData)
        if accelerationDataBuffer.count > timeWindow {
            accelerationDataBuffer.removeFirst()
        }
        
        // Update chart data
        chartDataX.append(newAccelerationData[0])
        chartDataY.append(newAccelerationData[1])
        chartDataZ.append(newAccelerationData[2])
        
       
        if chartDataX.count > dataLimit { chartDataX.removeFirst() }
        if chartDataY.count > dataLimit { chartDataY.removeFirst() }
        if chartDataZ.count > dataLimit { chartDataZ.removeFirst() }
        
    }
    
    // RUNNING MODEL INFERENCE
    func runInference() {
        let features = preprocessData(accelerationDataBuffer)
        
        
        guard let interpreter = interpreter else {
            print("Interpreter has not been initialized")
            return
        }
        
        var inputData = Data()
        for feature in features {
            var floatFeature = feature
            let featureBytes = Data(buffer: UnsafeBufferPointer(start: &floatFeature, count: 1))
            inputData.append(featureBytes)
        }
        
        do {
            try interpreter.allocateTensors()
            try interpreter.copy(inputData, toInputAt: 0)
            try interpreter.invoke()
            let outputTensor = try interpreter.output(at: 0)
            let results: [Float] = [Float](unsafeData: outputTensor.data) ?? []
            
            print("Model Output: \(results)")
            
            if results.contains(1){
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)){
                }
                if checkForSpeedDrop(){
                }
                handleFallDetected()
            }
            
            accelerationDataBuffer.removeAll()
        } catch {
            print("error")
        }
    }
    
    //PRE PROCESSING AND FEATURE CALCULATION
    func preprocessData(_ data: [[Double]]) -> [Float] {
        let xData = data.map { $0[0] }
        let yData = data.map { $0[1] }
        let zData = data.map { $0[2] }
        
        let standardizedX = standardize(xData)
        let standardizedY = standardize(yData)
        let standardizedZ = standardize(zData)
        
        let features = [
            calculateMean(standardizedX), calculateMean(standardizedY), calculateMean(standardizedZ),
            calculateStd(standardizedX), calculateStd(standardizedY), calculateStd(standardizedZ),
            calculateEnergy(standardizedX) + calculateEnergy(standardizedY) + calculateEnergy(standardizedZ),
            calculateSMA(standardizedX), calculateSMA(standardizedY), calculateSMA(standardizedZ)
        ].map(Float.init)
        
        return features
    }
    
    func calculateMean(_ data: [Double]) -> Double {
        return data.reduce(0, +) / Double(data.count)
    }
    
    func calculateStd(_ data: [Double]) -> Double {
        let mean = calculateMean(data)
        return sqrt(data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count))
    }
    
    func calculateEnergy(_ data: [Double]) -> Double {
        return data.map { pow($0, 2) }.reduce(0, +)
    }
    
    func calculateSMA(_ data: [Double]) -> Double {
        return calculateMean(data.map(abs))
    }
    
    func standardize(_ data: [Double]) -> [Double] {
        let mean = calculateMean(data)
        let std = calculateStd(data)
        return data.map { std == 0 ? $0 : ($0 - mean) / std }
    }
    //checkoing for significant drop in speed as potential indicator of fall
    func checkForSpeedDrop() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            let currentSpeed = locationManager.location?.speed ?? 0.0
            if currentSpeed < (previousSpeed / 5) { // Threshold of a significant drop
                return true  // Speed drop detected
            }
        }
        return false
    }
}

//extension to allow conversion from data to specific types

extension Array where Element: FloatingPoint {
    init?(unsafeData: Data) {
        let size = MemoryLayout<Element>.size
        guard unsafeData.count % size == 0 else { return nil }
        self = unsafeData.withUnsafeBytes {
            .init($0.bindMemory(to: Element.self))}
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(FallDetectionViewModel())
    }
}
