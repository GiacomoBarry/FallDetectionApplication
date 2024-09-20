import SwiftUI


struct SettingsView: View {
    //uses appstorage to store emergency contact number
    @AppStorage("emergencyContact") private var emergencyContact = ""
    @EnvironmentObject var viewModel: FallDetectionViewModel
    
    
    var body: some View {
        NavigationView {
            
            ZStack{
                Color("PrimaryColour").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20){
                                    VStack (spacing:20) {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundColor(Color("SecondaryColour"))
                                            .frame(width: 50.0, height: 50.0)
                                            .shadow(radius: 20)
                                            .imageScale(.large)
                                            .font(.largeTitle)
                                            .padding(.bottom,20)
                      
                        
                        VStack(spacing: 15){
                            TextField("Emergency Contact Number", text: $emergencyContact)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                            
                           
                       
                            Button("Test Fall Detection") {
                                viewModel.triggerFallDetection = true
                            }
                            .foregroundColor(Color.white)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(14)
                            .font(.headline)
                            .shadow(radius: 2)
                        }
                        .padding(.top, 20) 
                        .padding(.horizontal, 60)
                    }
                    .navigationTitle("")
                   
                }
            }
        }
    }
}
    
    struct SettingsView_Previews: PreviewProvider {
        static var previews: some View {
            SettingsView().environmentObject(FallDetectionViewModel())
        }
    }

