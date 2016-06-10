//
//  ViewController.swift
//  going-local
//
//  Created by Dide van Berkel on 04-04-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var checkBox: UIButton!
    let checkedImage = UIImage(named: "check")! as UIImage
    let uncheckedImage = UIImage(named: "uncheck")! as UIImage
    
    @IBOutlet weak var readLbl: UILabel!
    @IBOutlet weak var readEulaLbl: UIButton!
    
    override func viewDidAppear(animated: Bool) {
        if NSUserDefaults.standardUserDefaults().boolForKey("isChecked") == true {
            if NSUserDefaults.standardUserDefaults().boolForKey("automaticallyLogin") == true {
                if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        if NSUserDefaults.standardUserDefaults().boolForKey("isChecked") == true {
            checkBox.hidden = true
            readLbl.hidden = true
            readEulaLbl.hidden = true
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    @IBAction func checkBoxTapped(sender: AnyObject) {
        if NSUserDefaults.standardUserDefaults().boolForKey("isChecked") == false {
            checkBox.setImage(checkedImage, forState: .Normal)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isChecked")
        } else if NSUserDefaults.standardUserDefaults().boolForKey("isChecked") == true {
            checkBox.setImage(uncheckedImage, forState: .Normal)
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "isChecked")
        }
    }
    
    
    @IBAction func fbButtonPressed(sender: UIButton!) {
        if NSUserDefaults.standardUserDefaults().boolForKey("isChecked") == true {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logInWithReadPermissions(["email"], fromViewController: self) { (facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) in
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else if facebookResult.isCancelled {
                print("Facebook login was cancelled")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                print("Successfully logged in with Facebook \(accessToken)")
                
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential, completion: { (authData, error) in
                
                    if error != nil {
                        print("Login failed")
                    } else {
                        print("Logged in! \(authData!)")
                            let exist = NSUserDefaults.standardUserDefaults().boolForKey("facebookAccountExists")
                            if exist != true {
                                let user = ["provider": credential.provider]
                                DataService.ds.createFirebaseUser(authData!.uid, user: user)
                                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "facebookAccountExists")
                            } else {
                                print("This fb account exists")
                            }
                        
                        NSUserDefaults.standardUserDefaults().setValue(String(authData!.uid), forKey: KEY_UID)
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "automaticallyLogin")
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                })
            }
        }
    } else {
        self.showErrorAlert("EULA", msg: "Please agree to the End User License Agreement")
        }
    }

    @IBAction func attemptLogin(sender: UIButton!) {
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            FIRAuth.auth()?.signInWithEmail(email, password: pwd, completion: { (authData, error) in
                if error != nil {
                    if error!.code == STATUS_ACCOUNT_NONEXIST {
                        self.showErrorAlert("Could not login", msg: "Email address doesn't exist")
                    } else if error!.code == STATUS_EMAIL_NONEXIST {
                        self.showErrorAlert("Could not login", msg: "The specified email address is invalid")
                    } else if error!.code == STATUS_PASSWORD_INVALID {
                        self.showErrorAlert("Could not login", msg: "The specified password is incorrect")
                    } else {
                        self.showErrorAlert("Could not login", msg: "An unknown error occurred")
                    }
                } else {
                    NSUserDefaults.standardUserDefaults().setValue(String(authData!.uid), forKey: KEY_UID)
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "automaticallyLogin")
                    if NSUserDefaults.standardUserDefaults().boolForKey("isChecked") == true {
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    } else {
                        self.showErrorAlert("EULA", msg: "Please agree to the End User License Agreement")
                    }
                }
            })
        } else {
            showErrorAlert("Email and Password required", msg: "You must enter an email and a password")
        }
    }
    
    @IBAction func attemptSignup(sender: UIButton!) {
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            FIRAuth.auth()?.createUserWithEmail(email, password: pwd, completion: { (authData, error) in
                if error != nil {
                    if error!.code == STATUS_EMAIL_NONEXIST {
                        self.showErrorAlert("Could not create account", msg: "The specified email address is invalid")
                    } else if error!.code == STATUS_EMAIL_USED {
                        self.showErrorAlert("Could not create account", msg: "The specified email address is already in use")
                    } else {
                        self.showErrorAlert("Could not create account", msg: "An unknown error occurred")
                    }
                } else {
                    NSUserDefaults.standardUserDefaults().setValue(authData!.uid, forKey: KEY_UID)
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "automaticallyLogin")
                        let user = ["provider": "email"]
                        DataService.ds.createFirebaseUser(authData!.uid, user: user)
                    if NSUserDefaults.standardUserDefaults().boolForKey("isChecked") == true {
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    } else {
                        self.showErrorAlert("EULA", msg: "Please agree to the End User License Agreement")
                    }
                }
            })
        } else {
            showErrorAlert("Email and Password required", msg: "You must enter an email and a password")
        }
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
}

