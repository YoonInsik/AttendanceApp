

import UIKit
import FirebaseAuth

class AuthViewController: UIViewController {

    private let logoImg: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "logo.png")
        return image
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "DOBBY"
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        return label
    }()
    
    private let emailField: UITextField = {
        let emailField = UITextField()
        emailField.placeholder = "Enter Email"
        emailField.layer.borderWidth = 1
        emailField.autocapitalizationType = .none
        emailField.layer.borderColor = UIColor.black.cgColor
        emailField.leftViewMode = .always
        emailField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        return emailField
    }()
    
    private let passwordField: UITextField = {
        let passwordField = UITextField()
        passwordField.placeholder = "Enter Password"
        passwordField.layer.borderWidth = 1
        passwordField.isSecureTextEntry = true
        passwordField.layer.borderColor = UIColor.black.cgColor
        passwordField.leftViewMode = .always
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        return passwordField
    }()
    
    private let button: UIButton = {
       let button = UIButton()
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.setTitle("로그인", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(logoImg)
        view.addSubview(label)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(button)

        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        logoImg.frame = CGRect(x: view.frame.size.width / 2 - 50,
                               y: 100,
                               width: 100,
                               height: 100)
        
        label.frame = CGRect(x: 0,
                             y: logoImg.frame.origin.y+logoImg.frame.size.height-30,
                             width: view.frame.size.width,
                             height: 80)
        
        emailField.frame = CGRect(x: 20,
                                  y: label.frame.origin.y+label.frame.size.height+10,
                                  width: view.frame.size.width-40,
                                  height: 50)
        
        passwordField.frame = CGRect(x: 20,
                                     y: emailField.frame.origin.y+emailField.frame.size.height+10,
                                     width: view.frame.size.width-40,
                                     height: 50)
        
        button.frame = CGRect(x: 20,
                              y: passwordField.frame.origin.y+passwordField.frame.size.height+30,
                              width: view.frame.size.width-40,
                              height: 52)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if FirebaseAuth.Auth.auth().currentUser == nil {
            emailField.becomeFirstResponder()
        }
    }

    @objc private func didTapButton() {
        print("Login Button Tapped")
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            print("Missing Field Data")
            return
        }
        
        // Auth 인스턴트 얻기
        // 로그인 시도
        // 실패시 로그인 실패 메시지 띄우기
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] result, error in
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                // Login Failuare
                strongSelf.showCreateAccount(email: email, password: password)
                return
            }
            
            print("Login Success")
            self?.performSegue(withIdentifier: "loginSegue", sender: self)

            strongSelf.emailField.resignFirstResponder()
            strongSelf.passwordField.resignFirstResponder()
        })
    }
    
    func showCreateAccount(email: String, password: String) {
        let alert = UIAlertController(title: "Create Account",
                                      message: "계정을 생성하시겠습니까?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "생성",
                                      style: .default,
                                      handler: {_ in
                                        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self] result, error in
                                            guard let strongSelf = self else {
                                                return
                                            }
                                            
                                            guard error == nil else {
                                                // Login Failuare
                                                print("Account creation failed")
                                                return
                                            }
                                            
                                            print("Login Success")
                                    
                                            strongSelf.emailField.resignFirstResponder()
                                            strongSelf.passwordField.resignFirstResponder()
                                        })
                                      }))
        alert.addAction(UIAlertAction(title: "취소",
                                      style: .cancel,
                                      handler: {_ in
                                        
                                      }))
        present(alert, animated: true)
    }
}

