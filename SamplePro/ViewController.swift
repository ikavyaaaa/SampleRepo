//
//  ViewController.swift
//  SamplePro
//
//  Created by Kavya on 01/09/22.
//

import UIKit

class ViewController: UIViewController {
    
    var name: String?
    var arrayNumber = ["1","2","3"]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        arrayNumber.forEach { item in
//            print(item)
//        }
//        
//        var a = 10
//        var b = 20
//        a = a + b
//        b = a - b
//        a = a - b
//        print(a)
//        print(b)
//        
//        var x = 5
//        var y = 7
//
//        x = x + y //12
//        y = x - y // -2
//        x = x - y //
//
//        print(x)
//        print(y)
//        
//        if a == 20 {
//            print("a is 20")
//        } else {
//            
//        }
//        
//        //arrayNumber[1].append(contentsOf: "5")
//        arrayNumber.insert("5", at: 1)
//        print("arrayNumber>",arrayNumber)
//        
//      
//        
//        for i in 1...10 {
//            DispatchQueue.global(qos: .background).async {
//                DispatchQueue.global(qos: .background).async {
//                    print("inner i",i)
//                }
//                print(i)
//            }
//        }
//        
//        
        
        var ah = 10
        var bh = { [ah] in
                print (ah)
                  return
        }
        ah += 10
        bh()
        
    }

   

}

