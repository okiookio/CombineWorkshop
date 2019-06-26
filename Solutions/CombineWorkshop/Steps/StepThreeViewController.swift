//
//  StepThreeViewController.swift
//  CombineWorkshop
//
//  Created by Antoine van der Lee on 16/06/2019.
//  Copyright © 2019 SwiftLee. All rights reserved.
//

import UIKit
import Combine

/*
 STEP 3:
 A classic sign up form!

 Validation rules are as followed:
 - Username should not exist yet
 - Password should be 8 characters or more
 - Password inputs should match
 - Password should not exist in the easy passwords list
 */

final class StepThreeViewController: UIViewController {

    private let registeredUsernames = ["Erica", "Paul", "Marina", "Benedikt", "Kateryna", "Antoine", "Sally", "Bas"]
    private let weakPasswords = ["password", "00000000", "swiftisland"]

    @IBOutlet private weak var nextButton: UIButton!
    private var validationSubscriber: AnyCancellable?

    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var passwordConfirmTextField: UITextField!

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordAgain: String = ""

    var validatedPassword: AnyPublisher<String?, Never> {
        return Publishers.CombineLatest($password, $passwordAgain) { password, passwordAgain -> String? in
            guard password == passwordAgain, password.count >= 8 else { return nil }
            return password
            }
            .map { self.weakPasswords.contains($0 ?? "") ? nil : $0 }
            .eraseToAnyPublisher()
    }

    var validatedCredentials: AnyPublisher<(String, String)?, Never> {
        return Publishers.CombineLatest(validatedUsername, validatedPassword) { username, password -> (String, String)? in
            guard let uname = username, let pwd = password else { return nil }
            return (uname, pwd)
            }
            .eraseToAnyPublisher()
    }

    var validatedUsername: AnyPublisher<String?, Never> {
        return $username
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap { username in
                return Publishers.Future { promise in
                    self.usernameAvailable(username) { available in
                        promise(.success(available ? username : nil))
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.validationSubscriber = self.validatedCredentials
            .map { $0 != nil }
            .receive(on: RunLoop.main)
            .assign(to: \.isEnabled, on: nextButton)
    }

    private func usernameAvailable(_ username: String, completion: (_ available: Bool) -> Void) {
        let usernameAvailable = !registeredUsernames.contains(username)
        completion(usernameAvailable)
    }

    @IBAction func usernameChanged(_ sender: UITextField) {
        username = sender.text ?? ""
    }

    @IBAction func passwordChanged(_ sender: UITextField) {
        password = sender.text ?? ""
    }

    @IBAction func passwordAgainChanged(_ sender: UITextField) {
        passwordAgain = sender.text ?? ""
    }

}

extension StepThreeViewController: WorkshopStepContaining {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        didFinish(.step3)
    }
}