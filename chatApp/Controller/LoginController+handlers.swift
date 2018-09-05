//
//  LoginController+handlers.swift
//  chatApp
//
//  Created by user on 03.09.2018.
//  Copyright © 2018 user. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @objc func handleSelectProfileImageView(_ recognizer: UITapGestureRecognizer) {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        print(info)   !!!
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleLoginRegister() {
        if loginRegisterSegmentControl.selectedSegmentIndex == 0 {
            handleLogin()
        } else {
            handleRegister()
        }
    }
    
    func handleLogin() {
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Form is not valid")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (data, error) in
            if error != nil {
                print(error as Any)
                return
            }
            // successfully logged in our user
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    self.navigationItem.title = dictionary["name"] as? String
                }
            })
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func handleRegister() {
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (data, error) in
            
            if error != nil {
                print(error as Any)
                return
            }
            
            guard let uid = data?.user.uid else { return }
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images/\(imageName).png")
            self.uploadProfileImageWith(storageRef: storageRef, completion: { (success) in
                if success {
                    let starsRef = storageRef
                    starsRef.downloadURL(completion: { (url, error) in
                        if error != nil {
                            print("ERROR : ", error as Any)
                            return
                        }
                        
                        if let profileImageUrl = url?.absoluteString {
                            let values = ["name": name,
                                         "email": email,
                                         "profileImageUrl": profileImageUrl
                                ] as [String : Any]
                            self.registerUserIntoDatabaseWithUID(uid: uid, values: values)
                        }
                        
                        print("URL : ", url as Any)
                    })
                }
            })
 
        }
    }
    
    func uploadProfileImageWith(storageRef: StorageReference, completion: @escaping (_ Success: Bool) -> ()) {
        
        if let uploadData = self.profileImageView.image?.pngData() {
            storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                if error != nil {
                    print(error as Any)
                    completion(false)
                    
                } else {
                    completion(true)
                }
            }
        }
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String, values: [String: Any]) {
        let ref = Database.database().reference(fromURL: "https://chatapp-47.firebaseio.com/")
        let userReference = ref.child("users").child(uid)
        let values = ["name": values["name"], "email": values["email"], "profileImageUrl": values["profileImageUrl"]]
        userReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err as Any)
                return
            }
            
            self.dismiss(animated: true, completion: nil)
            print("Saved user succeffully in firebase DB")
        })
    }

    
}

