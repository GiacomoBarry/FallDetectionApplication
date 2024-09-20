import SwiftUI
import Firebase


//sign up view and enum which toggles between login and sign up

struct SignUpView: View {
    enum AuthMode {
        case login, signUp
    }

    @State private var email = ""
    @State private var password = ""
    @State private var authMode: AuthMode = .login
    @State private var errorMessage: String?
    @State private var isAuthenticated = false

    var body: some View {
        NavigationView {
            
            ZStack{
                Color("PrimaryColour").edgesIgnoringSafeArea(.all)
                
                VStack (spacing:20) {
                    Image(systemName: "figure.fall.circle.fill")
                        .foregroundColor(Color("SecondaryColour"))
                        .frame(width: 50.0, height: 50.0)
                        .shadow(radius: 20)
                        .imageScale(/*@START_MENU_TOKEN@*/.large/*@END_MENU_TOKEN@*/)
                        .font(.largeTitle)
                        .padding(.top,20)
                    
                    Picker("Mode", selection: $authMode) {
                        Text("Log In").tag(AuthMode.login)
                        Text("Sign Up").tag(AuthMode.signUp)
                    }
                    
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    .shadow(radius: 3)
                    
                    VStack(spacing: 15){
                        CustomTextField(placeholder: Text("Email").foregroundColor(Color("SecondaryColour")), text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                        
                        CustomTextField(placeholder: Text("Password").foregroundColor(Color("SecondaryColour")), text: $password, isSecure: true)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal, 20)
                    
                    //button which triggers either log in or sign up
                    VStack(spacing: 15){
                        Button(authMode == .login ? "Log In" : "Sign Up") {
                            validateInputs()
                            
                        }
                        .padding()
                        .foregroundColor(Color.white)
                        .background(Color("SecondaryColour"))
                        .cornerRadius(14)
                        .shadow(radius: 2)
                        .font(.system(size: 16, weight: .bold))
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AccentColour"))
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    // navigation link that passs you to the main content page on successsful authentication using firebase
                    NavigationLink(
                                            destination: ContentView(),
                                            isActive: $isAuthenticated,
                                            label: {
                                                EmptyView()
                                            }
                                        )
                }
                
                .keyboardResponsive() //adjusts the view when keyboard is in use
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(false)
        }
    }
    

    func validateInputs() {
        if !email.isValidEmail {
            errorMessage = "Invalid email format"
            return
        }
        
        if !password.isValidPassword {
            errorMessage = "Password must include at least 8 characters, a number, and a symbol"
            return
        }
        
        errorMessage = nil  // Clear any previous error message
        if authMode == .login {
            logIn()
        } else {
            signUp()
        }
    }
//firebase login
    private func logIn() {
        // Implement login functionality
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                // Handle successful login
                print("User logged in successfully")
                isAuthenticated = true
            }
        }
    }
    
    //firebase sign up

    private func signUp() {
        // Implement sign-up functionality
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                // Handle successful sign up
                print("User signed up successfully")
                isAuthenticated = true
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
//textfield for custom email and password textboxes
struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                placeholder
            }
            if isSecure {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
            }
        }
    }
}

struct KeyboardResponsiveModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, offset)
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { notif in
                    let value = notif.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                    let height = value.height
                    offset = height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    offset = 0
                }
            }
    }
}

extension View {
    func keyboardResponsive() -> some View {
        self.modifier(KeyboardResponsiveModifier())
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}

// Extension for validating email and password
extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidPassword: Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*\\d)(?=.*[$@$!%*#?&])[A-Za-z\\d$@$!%*#?&]{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: self)
    }
}
