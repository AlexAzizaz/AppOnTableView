//
//  StorageManager.swift
//  AppOnTableView
//
//  Created by onyx on 17.02.2020.
//  Copyright © 2020 Alex Al. All rights reserved.
//

import RealmSwift

let realm = try! Realm()


class StorageManager {
    
    static func saveObject(_ place: Place){
        
        try! realm.write {
            realm.add(place)
        }
    }
    
    
}
