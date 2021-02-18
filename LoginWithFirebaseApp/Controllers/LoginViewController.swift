//
//  LoginViewController.swift
//  LoginWithFirebaseApp
//
//  Created by 野津天志 on 2021/02/17.
//

import UIKit
import Firebase
import PKHUD

class LoginViewController : UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var dontHaveAccountButton: UIButton!
    
    @IBAction func tappedLoginButton(_ sender: Any) {
        HUD.show(.progress, onView: self.view)
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        //新規登録と違ってauthのsignInプロパティを使う
        Auth.auth().signIn(withEmail: email, password: password){(res, err) in
            if let err = err{
                print("ログイン情報の取得に失敗しました: ",err)
                return
            }
            print("ログインに成功しました。")
            guard let uid = Auth.auth().currentUser?.uid else { return }
            //ユーザー情報を変数でまとめる
            let userRef = Firestore.firestore().collection("users").document(uid)
            userRef.getDocument{( snapshot, err) in
                if let err = err {
                    print("ユーザー情報の取得に失敗しました。\(err)")
                    HUD.hide{(_) in
                        HUD.flash(.error, delay: 1)
                    }
                    return
                }
                guard let data = snapshot?.data() else { return }
                //作成したユーザーモデルの型に変換
                let user = User.init(dic: data)
                print("ユーザー情報の取得に成功しました。\(user)")
                
                HUD.hide{(_) in
//                    HUD.flash(.success, delay: 1)
                    HUD.flash(.success, onView: self.view, delay: 1){ (_) in
                        //画面遷移(->Home)
                        self.presentToHomeViewController(user: user)
                    }
                }
            }
        }
    }
    
    private func presentToHomeViewController(user: User){
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeViewController = storyboard.instantiateViewController(identifier: "HomeViewController") as HomeViewController
        //homeViewControllerのuserにviewControllerのユーザー情報を渡す。
        homeViewController.user = user
        homeViewController.modalPresentationStyle = .fullScreen
        self.present(homeViewController, animated: true, completion: nil)
    }
    
    @IBAction func tappedDontHaveAccountButton(_ sender: Any) {
        //前の画面に戻る
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //loginButtonボタンの角丸の処理
        loginButton.layer.cornerRadius = 10
        //loginButtonボタンの使用不可
        loginButton.isEnabled = false
        //loginButtonの基本色
        loginButton.backgroundColor = UIColor.rgb(red: 255, green: 211, blue: 187)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        
    }
}
//MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate{
    //textFieldの内容を受け取れる
    func textFieldDidChangeSelection(_ textField: UITextField) {
        //textFieldの中身が入っているか
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        //registerボタンの使用できるかの有無
        //全ての入力欄の中身が入っている場合true
        if emailIsEmpty || passwordIsEmpty {
            //registerボタンの使用不可
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.rgb(red: 255, green: 211, blue: 187)
        } else {
            //registerボタンの使用可
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor.rgb(red: 255, green: 141, blue: 0)
        }
        
    }
}
