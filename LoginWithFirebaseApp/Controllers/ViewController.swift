//
//  ViewController.swift
//  LoginWithFirebaseApp
//
//  Created by 野津天志 on 2021/02/01.
//

import UIKit
import Firebase
import PKHUD

//ユーザーのモデル
struct User {
    let name: String
    let email: String
    let createdAt: Timestamp
    
    init(dic: [String: Any]) {
        self.name = dic["name"] as! String
        self.email = dic["email"] as! String
        self.createdAt = dic["createdAt"] as! Timestamp
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    //registerButtonが押されたらhandleAuthToFirebaseメソッドを呼び出す
    @IBAction func tappedRegisterButton(_ sender: Any) {
        handleAuthToFirebase()
    }
    
    @IBAction func tappedAlreadyHaveAccountButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let homeViewController = storyboard.instantiateViewController(identifier: "LoginViewController") as LoginViewController
        //横にスライドするように画面遷移する
        navigationController?.pushViewController(homeViewController, animated: true)
//        self.present(homeViewController, animated: true, completion: nil)
    }
    //メール、パスワードの認証
    //データベース格納
    private func handleAuthToFirebase() {
        //ロードの作成(始まり)
        HUD.show(.progress, onView: view)
        //メール、パスワードの入力内容を変数にそれぞれ代入
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        //authのcreateUserメソッドを使ってfirebaseに認証情報を保存する
        Auth.auth().createUser(withEmail: email, password: password){ (res,err) in
            //エラーが起きた場合の文とエラーの内容を返す
            if let err = err{
                print("認証情報の保存に失敗しました。\(err)")
                HUD.hide{(_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            //作成したaddUserInfoToFireStoreを呼び出す
            self.addUserInfoToFireStore(email: email)
        }
    }
    //firestoreに情報を格納するメソッド
    private func addUserInfoToFireStore(email: String){
        //ユーザーidを取得
        guard let uid = Auth.auth().currentUser?.uid else { return }
        //ユーザーネーム取得
        guard let name = self.usernameTextField.text else { return }
        //格納する内容を変数に代入、辞書型
        //Timestampメソッドで時刻を保存
        let docData = ["email": email, "name": name, "createdAt": Timestamp()] as [String : Any]
        //ユーザー情報を変数でまとめる
        let userRef = Firestore.firestore().collection("users").document(uid)
        
        //firestoreのcolloctionを作成
        userRef.setData(docData){ ( err ) in
            if let err = err{
                print("Firestoreへの保存に失敗しました。\(err)")
                HUD.hide{(_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            //エラーが出なかった場合
            print("Firestoreへの保存に成功しました。")
            //firestoreから情報を引っ張ってくる時の処理
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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //registerボタンの角丸の処理
        registerButton.layer.cornerRadius = 10
        //registerボタンの使用不可
        registerButton.isEnabled = false
        //registerButtonの基本色
        registerButton.backgroundColor = UIColor.rgb(red: 255, green: 211, blue: 187)
        //textFieldのdelegateを使えるようにする
        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self
       
        //NotificationCenter(キーボードから通知を受け取るもの)
        //キーボードが開かれたときにshowKeyboardメソッドを呼び出す
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        //キーボードが開かれたときにhideKeyboardメソッドを呼び出す
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //ナビゲーションバーを非表示にする
        navigationController?.navigationBar.isHidden = true
        
    }
    
    
    //キーボードが開かれたときに呼び出される
    @objc func showKeyboard(notification: Notification) {
        //キーボードのサイズを取得する
        let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        //キーボードが表示された時のYの高さを取得する(値がnilなら処理を終わらせる)
        guard let keyboardMinY = keyboardFrame?.minY else { return }
        //registerButtonのYの高さを取得する
        let registerButtonMaxY = registerButton.frame.maxY
        //差分を求めて、ぴったりにならないように20プラスする
        let distance = registerButtonMaxY - keyboardMinY + 20
        //動かす位置の指定
        let transform = CGAffineTransform(translationX: 0, y: -distance)
        //animationを使用して大元のviewを動かす
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations:{
            self.view.transform = transform
        })
    }
    
    @objc func hideKeyboard(notification: Notification) {
        //大元のviewの位置を元に戻す
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations:{
            self.view.transform = .identity
        })
    }
    
    //viewの他の部分をタッチすると、キーボードが閉じる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }


}
//MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate{
    //textFieldの内容を受け取れる
    func textFieldDidChangeSelection(_ textField: UITextField) {
        //textFieldの中身が入っているか
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        let usernameIsEmpty = usernameTextField.text?.isEmpty ?? true
        //registerボタンの使用できるかの有無
        //全ての入力欄の中身が入っている場合true
        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty {
            //registerボタンの使用不可
            registerButton.isEnabled = false
            registerButton.backgroundColor = UIColor.rgb(red: 255, green: 211, blue: 187)
        } else {
            //registerボタンの使用可
            registerButton.isEnabled = true
            registerButton.backgroundColor = UIColor.rgb(red: 255, green: 141, blue: 0)
        }
        
    }
}

