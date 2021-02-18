//
//  HomeViewController.swift
//  LoginWithFirebaseApp
//
//  Created by 野津天志 on 2021/02/14.
//

import Foundation
import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    var user: User? {
        didSet{
            print("user: ",user as Any)
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBAction func tappedLogoutButton(_ sender: Any) {
        hundleLogout()
    }
    //firebaseからサインアウト
    //do,catch文でエラー解除
    private func hundleLogout(){
        do{
            try Auth.auth().signOut()
            pressentToMainViewController()
        }catch(let err){
            print("ログアウトに失敗しました。\(err)")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoutButton.layer.cornerRadius = 10
        //ユーザー情報の反映
        //エラーチェックをすることでoptionalの問題を回避
        if let user = user{
            nameLabel.text = user.name + "さんようこそ"
            emailLabel.text = user.email
            let dateString = dateFormatterForCreatedAt(date: user.createdAt.dateValue())
            dateLabel.text = "作成日:  " + dateString
        }
    }
    //開かれた時にログイン中かどうか確認する
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        confirmLoggedInUser()
    }
    //viewDidAppearで呼び出されるメソッド
    //ユーザーがログイン状態でなかったら登録画面に遷移する
    private func confirmLoggedInUser(){
        //ユーザーの情報がnilの場合
        if Auth.auth().currentUser?.uid == nil || user == nil{
            pressentToMainViewController()
        }
    }
    private func pressentToMainViewController(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: "ViewController") as ViewController
        //naviが出て遷移できるようになる
        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    //日本時間に変換
    private func dateFormatterForCreatedAt(date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
