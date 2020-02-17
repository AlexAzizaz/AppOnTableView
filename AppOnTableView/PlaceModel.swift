//
//  PlaceModel.swift
//  AppOnTableView
//
//  Created by onyx on 12.02.2020.
//  Copyright © 2020 Alex Al. All rights reserved.
//

import RealmSwift

class Place: Object {
    
    @objc dynamic var name = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?
    
    let restaurantNames = [
            "Burger Heroes", "Kitchen", "Bonsai", "Дастархан",
            "Индокитай", "X.O", "Балкан Гриль", "Sherlock Holmes",
            "Speak Easy", "Morris Pub", "Вкусные истории",
            "Классик", "Love&Life", "Шок", "Бочка"
        ]
    
    func savePlaces() {
        
        for place in restaurantNames {
            
            let image = UIImage(named: place)
            guard let imageData = image?.pngData() else { return }
            
            let newPlaces = Place()
            newPlaces.name = place
            newPlaces.location = "Moscwa"
            newPlaces.type = "Restaurant"
            newPlaces.imageData = imageData
            
            StorageManager.saveObject(newPlaces)
            
        }
        
    }
}
