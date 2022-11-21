//
//  SavedCodeDelegate.swift
//  Extension
//
//  Created by Huy Bui on 2022-11-19.
//

import UIKit

protocol SavedCodeDelegate: AnyObject {
    func didSelectSavedCode(withKey key: String)
    func deleteSavedCode(withKey key: String)
}
