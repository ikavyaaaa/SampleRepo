//
//  CBPresetsTableViewController.swift
//  CrewBid iPad
//
//  Created by Kavya on 08/02/22.
//

import UIKit
import CoreData

class CBPresetsTableViewController: BaseViewController {

    @IBOutlet weak var btnFilter: UIButton!
    @IBOutlet weak var btnSort: UIButton!
    @IBOutlet weak var btnPreset: UIButton!
    @IBOutlet weak var btnBids: UIButton!
    @IBOutlet weak var btnBidListCount: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    let commuteView = CBCommuteInfoViewController()
    var btnBidListLineCount: UIButton!
    var bidPeriod: BIBidPeriod!
    var array = [BIPreset]()
    var keyboardVisible: Bool = false
    var justChangedPresets: Bool = false
    var justAddedAPreset: Bool = false
    let presetDefaultName = "Untitled Preset "
    //var calendarData: BICalendarData!
    var calendarData: BICalendarData = BICalendarData()
    override func viewDidLoad() {
        super.viewDidLoad()
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        calendarData = calendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        setupUI()
        updatePresets()
        NotificationCenter.default.addObserver(self, selector: #selector(updateBidListCount), name: NSNotification.Name("updateBidListCount"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePresets), name: NSNotification.Name("refreshLines"), object: nil)
    }
    
    @objc func updatePresets(){
        let fetch = NSFetchRequest<NSFetchRequestResult>()
        fetch.entity = NSEntityDescription.entity(forEntityName: "BIPreset", in: bidPeriod.managedObjectContext!)
        do {
            array = try bidPeriod.managedObjectContext!.fetch(fetch) as! [BIPreset]
        } catch  {
            print(error)
        }
        self.tableView.reloadData()
    }
    
    func setupUI(){
        tableView.delegate = self
        tableView.dataSource = self
        btnBidListCount.layer.cornerRadius = 12
        updateBidListCount()
    }
    
    @objc func updateBidListCount(){
        var linesArray : [BILine] = []
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            linesArray.append(line)
        }
        var array : [NSPredicate] = []
        array.append(NSPredicate(format: "bidOrder > %@", NSNumber(integerLiteral: 0)))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        linesArray = (linesArray as NSArray).filtered(using: predicate) as! [BILine]
        DispatchQueue.main.async {
            self.btnBidListCount.setTitle("\(linesArray.count)", for: .normal)
        }
    }

    @IBAction func btnFilterAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBFilterRulesTableViewController") as! CBFilterRulesTableViewController
        self.navigationController?.pushViewController(vc, animated: false)
    }
    @IBAction func btnSortAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBLineSortsTableViewController") as! CBLineSortsTableViewController
        self.navigationController?.pushViewController(vc, animated: false)
    }
    @IBAction func btnPresetAction(_ sender: Any) {
        
    }
    @IBAction func btnBidsAction(_ sender: Any) {
        let vc = UIStoryboard.init(name: "BidDocument", bundle: Bundle.main).instantiateViewController(withIdentifier: "CBBIdListViewController") as! CBBIdListViewController
        self.navigationController?.pushViewController(vc, animated: false)
        UIView.transition(from: self.view, to: vc.view, duration: 0.85, options: [.transitionFlipFromLeft])
    }
    @IBAction func btnBidListCountAction(_ sender: Any) {
    }
    
    
    private func makeDefaultPresetName() -> String {
        var nameNumArray = [Int]()
        var firstDefaultAllowed: Bool = true
        for preset in self.array {
            if let presetName = preset.presetName {
                if presetName.contains(presetDefaultName) {
                    let delCharSet = NSCharacterSet(charactersIn: presetDefaultName)
                    let trimmedPresetName = presetName.trimmingCharacters(in: delCharSet as CharacterSet)
                    if trimmedPresetName == "" {
                        firstDefaultAllowed = false
                    }
                    if trimmedPresetName.isInt {
                        nameNumArray.append(Int(trimmedPresetName)!)
                    }
                }
            }
        }
        if firstDefaultAllowed {
            return presetDefaultName
        }
        else if nameNumArray.count == 0 && !firstDefaultAllowed {
            return presetDefaultName + "1"
        }
        else if nameNumArray.count > 0 {
            for i in 1 ..< (nameNumArray.count + 1) {
                if !nameNumArray.contains(i) {
                    return presetDefaultName + "\(i)"
                }
            }
            let currentLargestNum = nameNumArray.max()!
            return presetDefaultName + "\(currentLargestNum + 1)"
        }
        return ""
    }


}

extension CBPresetsTableViewController : CBPresetCellDelegate {
    func deleteButtonPressed(presetCell: CBPresetCell) {
        if !keyboardVisible {
            var indexPath = self.tableView.indexPathForRow(at: presetCell.center)
            if indexPath != nil {
                indexPath = presetCell.indexPath
            }
            if (indexPath!.row < self.array.count) {
                let obj = array[indexPath!.row]
                self.bidPeriod.managedObjectContext!.delete(obj)
            }else{
                print("Error : Index out of bound")
            }
            try? bidPeriod.managedObjectContext!.save()
            self.updatePresets()
        }
    }
    
    func nameTextFieldEndedEditing(presetCell: CBPresetCell) {
        var indexPath = presetCell.indexPath
        if indexPath != nil {
            indexPath = presetCell.indexPath
        }
        if indexPath!.row >= self.array.count {
            return
        }
        print("cell Row- \(String(describing: indexPath?.row)), arraycount--\(self.array.count)")
        let preset = self.array[indexPath!.row]
        // change by Francis 3 Jul 2020
        if presetCell.nameTextField.text == "" {
            preset.presetName = self.makeDefaultPresetName()
        } else {
            preset.presetName = presetCell.nameTextField.text
        }
        try? bidPeriod.managedObjectContext!.save()
        self.updatePresets()
    }
}

extension CBPresetsTableViewController : UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.array.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let presetCell = tableView.dequeueReusableCell(withIdentifier: "presetCell", for: indexPath) as! CBPresetCell
        presetCell.contentView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: presetCell.frame.height)
        if indexPath.row == self.array.count {
            // Preset addinf type cell
            presetCell.nameLabel.text = "New Preset With Current Settings"
            presetCell.backgroundColor = CBColor.tableViewBackgroundColor()
            let deleteButton = presetCell.contentView.viewWithTag(55)
            deleteButton?.alpha = 0.0
            presetCell.nameTextField.alpha = 0.0
            presetCell.nameLabel.alpha = 1.0
            presetCell.nameLabel.textColor = .black
            presetCell.nameTextField.textColor = .black
            presetCell.addButton.alpha = 1.0
            presetCell.deleteButton.alpha = 0.0
            presetCell.loadLabel.alpha = 0.0
        } else {
            // Added preset cell
            let preset = self.array[indexPath.row]
            presetCell.nameLabel.text = preset.presetName
            presetCell.Delegate = self
            presetCell.nameLabel.alpha = 0.0
            presetCell.nameTextField.alpha = 1.0
            presetCell.nameTextField.text = preset.presetName
            presetCell.nameTextField.borderStyle = .none
            presetCell.indexPath = indexPath
            if preset.presetIdentifier == self.bidPeriod.loadedPresetIdentifier {
                presetCell.loadLabel.alpha = 1
                presetCell.loadLabel.layer.borderColor = CBColor.purpleColor().cgColor
                if UserDefaults.standard.bool(forKey: kCBNightTimeModeEnabled) {
                    presetCell.loadLabel.textColor = .white
                } else {
                    presetCell.loadLabel.textColor = CBColor.buttonDarkTextColor()
                }
                presetCell.loadLabel.text = "Loaded"
            } else {
                presetCell.nameLabel.textColor = .black
                presetCell.nameTextField.textColor = .black
                presetCell.loadLabel.alpha = 0.6
                presetCell.loadLabel.layer.borderColor = CBColor.buttonLightTextColor()?.cgColor
                presetCell.loadLabel.textColor = CBColor.buttonLightTextColor()
                presetCell.loadLabel.text = "Load"
            }
            if justAddedAPreset && indexPath.row == self.array.count - 1 {
                // set textfield editing
                presetCell.nameTextField.becomeFirstResponder()
                justAddedAPreset = false
            }
            presetCell.addButton.alpha = 0.0
            presetCell.deleteButton.alpha = 1.0
        }
        return presetCell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if keyboardVisible {
            return
        }
        // If user selected the last row, add a preset
        if indexPath.row == self.array.count {
            UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
            if (self.bidPeriod!.loadedPresetIdentifier != nil) {
                
            }
            
            let presetEntity = NSEntityDescription.entity(forEntityName: "BIPreset", in: bidPeriod.managedObjectContext!)
            let preset = BIPreset(entity: presetEntity!, insertInto: bidPeriod.managedObjectContext!)
            preset.selected = NSNumber(value: true)
            preset.month = bidPeriod.month
            preset.year = bidPeriod.year
            preset.presetName = "Preset\(self.array.count + 1)"
            preset.presetIdentifier = CBUtils.generateUniqueIdentifier()
            preset.filterSortState = self.getPresetDict() as NSObject
            preset.position = CBGlobalMethods.shortNameOf(type: BICrewPositionType(rawValue: bidPeriod.positionType!.intValue) ?? .Captain)
            try? bidPeriod.managedObjectContext?.save()
            self.updatePresets()
        } else {
            let presetObj = self.array[indexPath.row]
            self.bidPeriod!.loadedPresetIdentifier = presetObj.presetIdentifier
            UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
            loadPreset(preset: presetObj)
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            
        }
    }
    
    func loadPreset(preset : BIPreset){
        if let dict = preset.filterSortState as? NSDictionary {
            if let lstQuickFilters = dict["lstQuickFilters"] as? [[String:Any]],
                let lstSorts = dict["lstSorts"] as? [[String:Any]],
                let lstFilters = dict["lstFilters"] as? [[String:Any]]  {
                setQuickFilterToLocalDB(details: lstQuickFilters[0])
                setFilterToLocalDB(details: lstFilters)
                setSortToLocalDB(details: lstSorts)
            }
            
        }
    }
    
    
    private func setSortToLocalDB(details: [[String: Any]]) {

        if let result = CBGlobalMethods.shared.selectedBidPeriod?.lineSorts?.allObjects as? [BILineSort] {
            for object in result {
                self.bidPeriod.managedObjectContext?.delete(object)
            }
        }
        
//        let commuteFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Commutability") // Find this name in your .xcdatamodeld file
//        commuteFetchRequest.predicate = NSPredicate(format: "commutableType == 1")
//        if let commuteResult = try? (self.bidPeriod.managedObjectContext?.fetch(commuteFetchRequest) as! [Commutability]) {
//            for commuteFilterRule in commuteResult {
//                // deleting commute filters if currently enabled.
//                self.bidPeriod.managedObjectContext?.delete(commuteFilterRule)
//            }
//        }
        
        
//        if let DefaultCommutingValues = details["DefaultCommutingValues"] as? NSDictionary {
//            if let MON_THURS_DEPART = DefaultCommutingValues["MON_THURS_DEPART"] as? String,
//                  let MON_THURS_RETURN = DefaultCommutingValues["MON_THURS_RETURN"] as? String,
//                  let FRI_DEPART = DefaultCommutingValues["FRI_DEPART"] as? String,
//                  let FRI_RETURN = DefaultCommutingValues["FRI_RETURN"] as? String,
//                  let SAT_DEPART = DefaultCommutingValues["SAT_DEPART"] as? String,
//                  let SAT_RETURN = DefaultCommutingValues["SAT_RETURN"] as? String,
//                  let SUN_DEPART = DefaultCommutingValues["SUN_DEPART"] as? String,
//                  let SUN_RETURN = DefaultCommutingValues["SUN_RETURN"] as? String,
//                  let NoMidCheckState = DefaultCommutingValues["NoMidCheckState"] as? Bool {
//
//                let defaultTimes = NSMutableArray(capacity: 8)
//
//                if (MON_THURS_DEPART.length) > 0  {
//                    let timedepartureMonThurs: Int? =  Int(MON_THURS_DEPART)!
//                    if timedepartureMonThurs! > -1 {
//                        defaultTimes.add(Int(MON_THURS_DEPART)!)
//                    } else {
//                        defaultTimes.add(-1)
//                    }
//                } else {
//                    defaultTimes.add(-1)
//                }
//                if (MON_THURS_RETURN.length) > 0  {
//                    let timereturnMonThurs: Int? = Int(MON_THURS_RETURN)!
//                    if timereturnMonThurs! < 3000  {
//                        defaultTimes.add(Int(MON_THURS_RETURN)!)
//                    } else {
//                        defaultTimes.add(3000)
//                    }
//                } else {
//                    defaultTimes.add(3000)
//                }
//                if (FRI_DEPART.length) > 0  {
//                    let timedepartureFri :Int? = Int(FRI_DEPART)!
//                    if timedepartureFri! > -1  {
//                        defaultTimes.add(Int(FRI_DEPART)!)
//                    } else {
//                        defaultTimes.add(-1)
//                    }
//                } else {
//                    defaultTimes.add(-1)
//                }
//                if (FRI_RETURN.length) > 0  {
//                    let timereturnFri :Int? = Int(FRI_RETURN)!
//                    if timereturnFri! < 3000 {
//                        defaultTimes.add(Int(FRI_RETURN)!)
//                    } else {
//                        defaultTimes.add(3000)
//                    }
//                } else {
//                    defaultTimes.add(3000)
//                }
//                if (SAT_DEPART.length) > 0  {
//                    let timedepartureSat :Int? = Int(SAT_DEPART)!
//
//                    if timedepartureSat! > -1 {
//                        defaultTimes.add(Int(SAT_DEPART)!)
//                    } else {
//                        defaultTimes.add(-1)
//                    }
//                } else {
//                    defaultTimes.add(-1)
//                }
//
//                if (SAT_RETURN.length) > 0  {
//                    let timereturnSat:  Int? = Int(SAT_RETURN)!
//
//                    if timereturnSat! < 3000  {
//                        defaultTimes.add(Int(SAT_RETURN)!)
//                    } else {
//                        defaultTimes.add(3000)
//                    }
//                } else {
//                    defaultTimes.add(3000)
//                }
//
//                if (SUN_DEPART.length) > 0  {
//                    let timedepartureSun:  Int? = Int(SUN_DEPART)!
//
//                    if timedepartureSun! > -1 {
//                        defaultTimes.add(Int(SUN_DEPART)!)
//                    } else {
//                        defaultTimes.add(-1)
//                    }
//                } else {
//                    defaultTimes.add(-1)
//                }
//
//                if (SUN_RETURN.length) > 0  {
//                    let timereturnSun:  Int? = Int(SUN_RETURN)!
//
//                    if timereturnSun! < 3000  {
//                        defaultTimes.add(Int(SUN_RETURN)!)
//                    } else {
//                        defaultTimes.add(3000)
//                    }
//                } else {
//                    defaultTimes.add(3000)
//                }
//                UserDefaults.standard.set(defaultTimes, forKey: kCBDefaultCommutingTimesKey)
//            }
//        }
        

        for sortDict in details {
            guard sortDict["ListSort"] != nil else {
                return
            }
            let subSorts = sortDict["ListSort"] as! [[String: Any]]
            // saveing each filters from the json to coredata.
            
            var linesortAutoCommute: [String : Any]!
            var order : Int = 0
            for subSort in subSorts {
                order += 1
                if subSort["Abbreviation"] as! String == "CmAuto"{
                    linesortAutoCommute =  subSort
                } else {
                    
                    let lineSort = NSEntityDescription.insertNewObject(forEntityName: BILineSortEntityName, into: self.bidPeriod.managedObjectContext!) as! BILineSort
                    lineSort.bidPeriod = self.bidPeriod
                    lineSort.abbreviation = (subSort["Abbreviation"] as! String)
                    let currentTitle = sortTitleDict[lineSort.abbreviation!]!
                    lineSort.category = (subSort["Category"] as! NSNumber)
                    if subSort["Type"] != nil {
                        lineSort.type = (subSort["Type"] as! NSNumber)
                    }
                    if subSort["ArrayVariables"] != nil {
                        lineSort.arrayVariables = (subSort["ArrayVariables"] as! NSArray)
                    }
                    lineSort.order = (subSort["Order"] as? NSNumber) ?? (order as NSNumber)
                    lineSort.name = (subSort["Name"] as! String)
                    if currentTitle == "Position" {
                        lineSort.keyPath = self.bidPeriod.lineSortKeyForPosition(posLineSort: lineSort)
                    } else {
                        lineSort.keyPath = (subSort["KeyPath"] as! String)
                    }
                    let ascending = (subSort["Ascending"] as! Bool)
                    lineSort.ascending = ascending ? 1: 0
                    lineSort.isMutable = (subSort["IsMutable"] as! NSNumber)
                    if subSort["City"] != nil {
                        lineSort.city = (subSort["City"] as! String)
                    }
                    
                    
                    
                    else if lineSort.abbreviation == "flag" {
                        var variable = [String: Any]()
                        for val in lineSort.arrayVariables as! [Int] {
                            if val == 0 {
                                variable["NO_COLOR_FLAG"] = val
                            }
                            else if val == 1 {
                                variable["BLUE_COLOR_FLAG"] = val
                            }
                            else if val == 2 {
                                variable["GREEN_COLOR_FLAG"] = val
                            }
                            else if val == 3 {
                                variable["RED_COLOR_FLAG"] = val
                            }
                            else if val == 4 {
                                variable["YELLOW_COLOR_FLAG"] = val
                            }
                            else if val == 5 {
                                variable["ORANGE_COLOR_FLAG"] = val
                            }
                        }
                        lineSort.variables = variable
                    }
                    else if lineSort.abbreviation == "OffSort" || lineSort.abbreviation == "WorkSort" || lineSort.abbreviation == "TripStartSort"{
                        lineSort.variables = (BILineSort.configureMonthDaySort(indices: subSort["ArrayVariables"] as? [Int] ?? []) as! [String : Any])
                        if lineSort.abbreviation == "OffSort" {
                            lineSort.keyPath = self.bidPeriod?.lineSortKeyForDaysOff(lineSort: lineSort)
                        }else if lineSort.abbreviation == "WorkSort" {
                            lineSort.keyPath = self.bidPeriod?.lineSortKeyForDaysWork(lineSort: lineSort)
                        }else if lineSort.abbreviation == "TripStartSort" {
                            lineSort.keyPath = self.bidPeriod?.lineSortKeyForTripStartDays(lineSort: lineSort)
                        }
                    }
                    else if lineSort.abbreviation == "Commute" {
                        let varb = subSort["Variable"] as! [String : Any]
                        var dict2 = [String: Any]()
                        varb.forEach { dict2[$0.0] = String(describing: $0.1) }
                        
                        if var val = dict2["FRI_RETURN"] {
                            if val as! String == "" {
                                val = "3000"
                            }
                            dict2["FRI_RETURN"] = (NSNumber(floatLiteral: Double(val as! String)!))
                        }
                        if var val = dict2["FRI_DEPART"] {
                            if val as! String == "" {
                                val = "-1"
                            }
                            dict2["FRI_DEPART"] = (NSNumber(floatLiteral: Double(val as! String)!))
                        }
                        if var val = dict2["MON_THURS_DEPART"] {
                            if val as! String == "" {
                                val = "-1"
                            }
                            dict2["MON_THURS_DEPART"] = (NSNumber(floatLiteral: Double(val as! String)!))
                        }
                        if var val = dict2["MON_THURS_RETURN"] {
                            if val as! String == "" {
                                val = "3000"
                            }
                            dict2["MON_THURS_RETURN"] = (NSNumber(floatLiteral: Double(val as! String)!))
                        }
                        if var val = dict2["SAT_DEPART"] {
                            if val as! String == "" {
                                val = "-1"
                            }
                            dict2["SAT_DEPART"] = (NSNumber(floatLiteral: Double(val as! String)!))
                        }
                        if var val = dict2["SAT_RETURN"] {
                            if val as! String == "" {
                                val = "3000"
                            }
                            dict2["SAT_RETURN"] = (NSNumber(floatLiteral: Double(val as! String)!))
                        }
                        if var val = dict2["SUN_RETURN"] {
                            if val as! String == "" {
                                val = "3000"
                            }
                            dict2["SUN_RETURN"] = (NSNumber(floatLiteral: Double(val as! String)!))
                        }
                        if var val = dict2["SUN_DEPART"] {
                            if val as! String == "" {
                                val = "-1"
                            }
                            dict2["SUN_DEPART"] = (NSNumber(floatLiteral: Double(val as! String)!))
                        }
                        if let val = dict2["NoMidCheckState"] {
                            dict2["NoMidCheckState"] = (NSNumber(floatLiteral: Double(val as! String)!).boolValue)
                        }
                        
                        lineSort.variables = dict2 as NSDictionary as? [AnyHashable : Any]
                    }
                    else if currentTitle == "Regional Overnight Cities" {
                        var variables = [String: Any]()
                        let variable = subSort["Variable"]
                        let setArray = (variable as! [String: Any])["CITY"] as! [Any]
                        let set = NSSet(array: setArray)
                        variables = ["SET": set]
                        lineSort.variables = (variables as [AnyHashable : Any])
                    } else {
                        if subSort["Variable"] != nil {
                            lineSort.variables = (subSort["Variable"] as! [AnyHashable : Any])
                        }
                    }
                    print("start///: \(lineSort) end///")
                }
                
            }
            
//            if let linesort = linesortAutoCommute {
//                print(linesort)
//                let varb = linesortAutoCommute["Variable"] as! [String : Any]
//                var dict2 = [String: Any]()
//                varb.forEach { dict2[$0.0] = String(describing: $0.1) }
//                var commuteCity = ""
//                var isNonStop = false
//                if let val = dict2["commuteCity"] {
//                    commuteCity = val as! String
//                }
//                if let val = dict2["nonStop"] {
//                    isNonStop = NSNumber(floatLiteral: Double(val as! String)!).boolValue
//                }
//                let commutVC = CommuteCityViewController()
//                commutVC.bidPeriod = self.bidPeriod
//
//                CBGlobalMethods.shared.showMBProgressHudOn(view: self.view, text: "Calculating commute values..")
//                CBGlobalMethods.shared.hud?.bezelView.color = UIColor(rgb: 0x035A01)
//                CBGlobalMethods.shared.hud?.label.textColor = .white
//
//                commutVC.commutabilityCalculationWithForSync(city: commuteCity, isNonStop: isNonStop) { (completed) in
//                    CBGlobalMethods.shared.hud?.hide(animated: true)
//
//                    let commuteInfoVC = CBCommuteInfoViewController()
//                    commuteInfoVC.backToBaseFromSync = dict2["selectedBackToBasePadTimeValues"] as? String
//
//                    let connectTime = dict2["selectedConnectTime"] as! String
//                    if connectTime == "--:--" {
//                        commuteInfoVC.connectTimeValue = "0:0"
//                    } else {
//                        commuteInfoVC.connectTimeValue = dict2["selectedConnectTime"] as! String
//                    }
//                    commuteInfoVC.checkInFromSync = dict2["selectedTakeOffPadTimeValues"] as? String
//                    commuteInfoVC.bidPeriod = self.bidPeriod
//                    commuteInfoVC.linesManager = self.linesManager
//                    commuteInfoVC.commutabilityType = CommutabilityType.sort
//                    commuteInfoVC.isNonStopFromSync = NSNumber(integerLiteral: Int(dict2["nonStop"] as! String)!).boolValue
//                    commuteInfoVC.commuteCityFromSync = dict2["commuteCity"] as? String
//
//                    commuteInfoVC.thirdCellValue = NSNumber(integerLiteral: Int(dict2["cmtFrBaOv"] as! String)!)
//
//                    commuteInfoVC.CalculateCommuteLineProperties(isFromSync: true)
//                }
//
//
//            }
            
        }
        
        do {
            try self.bidPeriod.managedObjectContext?.save()
        } catch {
            print(error)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    
    }
    
    
    
    private func setFilterToLocalDB(details: [[String: Any]]) {

//        let commuteFetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Commutability")
//        commuteFetchRequest.predicate = NSPredicate(format: "commutableType == 0")
//        if let commuteResult = try? (self.bidPeriod.managedObjectContext?.fetch(commuteFetchRequest) as! [Commutability]) {
//            for commuteFilterRule in commuteResult {
//                // deleting commute filters if currently enabled.
//                self.bidPeriod.managedObjectContext?.delete(commuteFilterRule)
//            }
//        }
//
        autoreleasepool {
            for filterDict in details {
                let subFilters = filterDict["Listfilter"] as! [[String: Any]]
                // saveing each filters from the json to coredata.

                var commuteValueDict: [String: Any]!
                var reportReleaseValueDict: [String: Any]!

                for subFilter in subFilters {
                    if (subFilter["Abbreviation"] as! String) == "CmAuto" {
                        commuteValueDict = subFilter
                    }
                    else if (subFilter["Abbreviation"] as! String) == "Report-Release" {
                        reportReleaseValueDict = subFilter
                    } else {
                        let filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
                        filterRule.abbreviation = (subFilter["Abbreviation"] as! String)
                        filterRule.category = (subFilter["Category"] as! NSNumber)
                        let typeInt = Int(subFilter["Type"] as! String)
                        filterRule.type = NSNumber(integerLiteral: typeInt!) //(subFilter["Type"] as! NSNumber)
                        filterRule.name = (subFilter["Name"] as! String)
                        filterRule.keyPath = (subFilter["KeyPath"] as! String)
                        filterRule.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
                        let currentTitle = filterTitleDict[filterRule.abbreviation!]!

                        if filterRule.abbreviation == "Flags" {
                            let set = NSSet(array: subFilter["Variable"] as! [Any])
                            let variable = ["SET" : set]
                            filterRule.variables = variable as NSDictionary
                        }
                        // commute manual
                        else if filterRule.abbreviation == "CRqd" {
//                            let varb = subFilter["Variable"] as! [String : Any]
//                            var dict2 = [String: Any]()
//                            dict2["FRI_DEPART"] = NSNumber(floatLiteral: Double("-1")!)
//                            dict2["MON_THURS_DEPART"] = NSNumber(floatLiteral: Double("-1")!)
//                            dict2["SAT_DEPART"] = NSNumber(floatLiteral: Double("-1")!)
//                            dict2["SUN_DEPART"] = NSNumber(floatLiteral: Double("-1")!)
//                            dict2["FRI_RETURN"] = NSNumber(floatLiteral: Double("3000")!)
//                            dict2["MON_THURS_RETURN"] = NSNumber(floatLiteral: Double("3000")!)
//                            dict2["SUN_RETURN"] = NSNumber(floatLiteral: Double("3000")!)
//                            dict2["SUN_RETURN"] = NSNumber(floatLiteral: Double("3000")!)
//                            varb.forEach { dict2[$0.0] = String(describing: $0.1) }
//                            if let val = dict2["VALUE"] {
//                                dict2["VALUE"] = (NSNumber(floatLiteral: Double(val as! String) ?? 0))
//                            }
//                            if let val = dict2["RANGEEND"] {
//                                dict2["RANGEEND"] = val as! String
//                            }
//                            if let val = dict2["RANGESTART"] {
//                                dict2["RANGESTART"] = val as! String
//                            }
//
//                            if var val = dict2["FRI_DEPART"] {
//                                if val as! String == "" {
//                                    val = "-1"
//                                }
//                                dict2["FRI_DEPART"] = (NSNumber(floatLiteral: Double(val as! String)!))
//                            }
//                            if var val = dict2["FRI_RETURN"] {
//                                if val as! String == "" {
//                                    val = "3000"
//                                }
//                                dict2["FRI_RETURN"] = (NSNumber(floatLiteral: Double(val as! String)!))
//                            }
//                            if var val = dict2["MON_THURS_DEPART"] {
//                                if val as! String == "" {
//                                    val = "-1"
//                                }
//                                dict2["MON_THURS_DEPART"] = (NSNumber(floatLiteral: Double(val as! String)!))
//                            }
//                            if var val = dict2["MON_THURS_RETURN"] {
//                                if val as! String == "" {
//                                    val = "3000"
//                                }
//                                dict2["MON_THURS_RETURN"] = (NSNumber(floatLiteral: Double(val as! String)!))
//                            }
//                            if var val = dict2["SAT_DEPART"] {
//                                if val as! String == "" {
//                                    val = "-1"
//                                }
//                                dict2["SAT_DEPART"] = (NSNumber(floatLiteral: Double(val as! String)!))
//                            }
//                            if var val = dict2["SAT_RETURN"] {
//                                if val as! String == "" {
//                                    val = "3000"
//                                }
//                                dict2["SAT_RETURN"] = (NSNumber(floatLiteral: Double(val as! String)!))
//                            }
//                            if var val = dict2["SUN_RETURN"] {
//                                if val as! String == "" {
//                                    val = "3000"
//                                }
//                                dict2["SUN_RETURN"] = (NSNumber(floatLiteral: Double(val as! String)!))
//                            }
//                            if var val = dict2["SUN_DEPART"] {
//                                if val as! String == "" {
//                                    val = "-1"
//                                }
//                                dict2["SUN_DEPART"] = (NSNumber(floatLiteral: Double(val as! String)!))
//                            }
//                            if let val = dict2["NoMidCheckState"] {
//                                dict2["NoMidCheckState"] = (NSNumber(floatLiteral: Double(val as! String)!).boolValue)
//                            }
//
//                            filterRule.variables = dict2 as NSDictionary
//                            let cell : CBCommutingRuleCell = CBCommutingRuleCell()
//                            cell.bidPeriod = self.bidPeriod
//                            cell.filterRule = filterRule
//                            cell.linesManager = self.linesManager
//                            cell.CalculateFilterFromSync(dict2 as NSDictionary)
                        }
                        else if filterRule.abbreviation == "OCB" {
                            var variables = [String: Any]()
                            let variable = subFilter["Variable"] as! [String: Any]
                            let overNightYesCities = variable["OverNightYes"] as! [String]
                            let overNightNoCities = variable["OverNightNo"] as! [String]

                            for overNightYesCity in overNightYesCities {
                                variables[overNightYesCity] = "2"
                            }
                            for overNightNoCity in overNightNoCities {
                                variables[overNightNoCity] = "1"
                            }
                            filterRule.variables = variables as NSDictionary
                        }
                        else if filterRule.abbreviation == "WantDays" || filterRule.abbreviation == "MonthDays" || filterRule.abbreviation == "TripStarts" {
                            filterRule.variables = BIFilterRule.configureMonthDayFilter(indices: subFilter["Variable"] as! [Int])
                        }
                        else if currentTitle == "Regional Overnight Cities" {
                            var variables = [String: Any]()
                            let variable = subFilter["Variable"]
                            let setArray = (variable as! [String: Any])["CITY"] as! [Any]
                            let set = NSSet(array: setArray)
                            variables = ["SET": set,
                                         "RANGEEND" : (variable as! [String: Any])["RANGEEND"] as! String,
                                         "RANGESTART" : (variable as! [String: Any])["RANGESTART"] as! String,
                                         "VALUE" : (variable as! [String: Any])["VALUE"] as! NSNumber]
                            filterRule.variables = variables as NSDictionary
                        }
                        else {
                            let varb = subFilter["Variable"] as! [String : Any]
                            var dict2 = [String: Any]()
                            varb.forEach { dict2[$0.0] = String(describing: $0.1) }
                            if let val = dict2["VALUE"] {
                                dict2["VALUE"] = (NSNumber(floatLiteral: Double(val as! String)!))
                            }
                            if let val = dict2["RANGEEND"] {
                                dict2["RANGEEND"] = val as! String
                            }
                            if let val = dict2["RANGESTART"] {
                                dict2["RANGESTART"] = val as! String
                            }
                            if let val = dict2["DECIMAL"] {
                                dict2["DECIMAL"] = (NSNumber(integerLiteral: Int(val as! String)!)).boolValue
                            }
                            if let val = dict2["STEP"] {
                                dict2["STEP"] = (NSNumber(floatLiteral: Double(val as! String)!))
                            }
                            if let val = dict2["NUMPLACES"] {
                                dict2["NUMPLACES"] = (NSNumber(floatLiteral: Double(val as! String)!))
                            }

                            filterRule.variables = dict2 as NSDictionary
                        }
                        filterRule.comparison = (subFilter["Comparison"] as! NSNumber)
                        if (filterRule.ruleHighlightsTrips()) {
                            filterRule.highlightTrips()
                        }

                     }
                }
//                if let commuteDict = commuteValueDict {
//                    let varb = commuteDict["Variable"] as! [String : Any]
//                    var dict2 = [String: Any]()
//                    varb.forEach { dict2[$0.0] = String(describing: $0.1) }
//                    var commuteCity = ""
//                    var isNonStop = false
//                    if let val = dict2["commuteCity"] {
//                        commuteCity = val as! String
//                    }
//                    if let val = dict2["nonStop"] {
//                        isNonStop = NSNumber(floatLiteral: Double(val as! String)!).boolValue
//                    }
//                    let commutVC = CommuteCityViewController()
//                    commutVC.bidPeriod = self.bidPeriod
//
//                    CBGlobalMethods.shared.showMBProgressHudOn(view: self.view, text: "Calculating commute values..")
//                    CBGlobalMethods.shared.hud?.bezelView.color = UIColor(rgb: 0x035A01)
//                    CBGlobalMethods.shared.hud?.label.textColor = .white
//
//                    commutVC.commutabilityCalculationWithForSync(city: commuteCity, isNonStop: isNonStop) { (completed) in
//                        CBGlobalMethods.shared.hud?.hide(animated: true)
//                        let commuteInfoVC = CBCommuteInfoViewController()
//                        commuteInfoVC.backToBaseFromSync = dict2["selectedBackToBasePadTimeValues"] as? String
//
//                        let connectTime = dict2["selectedConnectTime"] as! String
//                        if connectTime == "--:--" {
//                            commuteInfoVC.connectTimeValue = "0:0"
//                        } else {
//                            commuteInfoVC.connectTimeValue = dict2["selectedConnectTime"] as! String
//                        }
//                        commuteInfoVC.checkInFromSync = dict2["selectedTakeOffPadTimeValues"] as? String
//                        commuteInfoVC.bidPeriod = self.bidPeriod
//                        commuteInfoVC.linesManager = self.linesManager
//                        commuteInfoVC.commutabilityType = CommutabilityType.filter
//                        commuteInfoVC.isNonStopFromSync = NSNumber(integerLiteral: Int(dict2["nonStop"] as! String)!).boolValue
//                        commuteInfoVC.commuteCityFromSync = dict2["commuteCity"] as? String
//                        commuteInfoVC.KeyPathFromSync = commuteDict["KeyPath"] as? String ?? "commutabilityOverall"
//                        commuteInfoVC.value = NSNumber(integerLiteral: Int(dict2["cmtPercentage"] as! String)!)
//                        commuteInfoVC.secondCellValue = NSNumber(integerLiteral: Int(dict2["nMid"] as! String)!)
//                        commuteInfoVC.thirdCellValue = NSNumber(integerLiteral: Int(dict2["cmtFrBaOv"] as! String)!)
//                        commuteInfoVC.type = NSNumber(integerLiteral: Int(dict2["cmtGreaterOrLesser"] as! String)!)
//
//                        commuteInfoVC.CalculateCommuteLineProperties(isFromSync: true)
//                    }
//                }
                
//                if let reportReleaseValueDict = reportReleaseValueDict {
//                    var varb = reportReleaseValueDict["Variable"] as! [String : Any]
//
//                    if varb["selectedOption"] == nil{
//                        if let isFirst = varb["isFirst"] as? Int, let isLast = varb["isLast"] as? Int {
//                            if isFirst != 0 || isLast != 0{
//                                varb["selectedOption"] = "1"
//                            }
//                        }else if let isFirst = varb["isFirst"] as? String, let isLast = varb["isLast"] as? String {
//                            if isFirst != "0" || isLast != "0"{
//                                varb["selectedOption"] = "1"
//                            }
//                        }else{
//                            varb["selectedOption"] = "0"
//                        }
//                        if varb["isCalendar"] as? Int == 1 || varb["isCalendar"] as? String == "1"{
//                            varb["selectedOption"] = "2"
//                        }
//                    }
//                    if varb["selectedOption"] != nil{
//                        var dict2 = [String: Any]()
//                        varb.forEach { dict2[$0.0] = String(describing: $0.1) }
//
//                        var reportValue = ""
//                        var releaseValue = ""
//                        var seletedIndices = [Int]()
//                        var seletedDates = [Any]()
//
//                        var isLast : NSNumber = 0;
//                        var isNoMid : NSNumber = 0;
//                        var isCalendar : NSNumber = 0;
//                        var isSelectedAll : NSNumber = 0;
//                        var isFirst : NSNumber = 0;
//                        var isAllDays : NSNumber = 0;
//
//
//                        if let val = dict2["isFirst"] {
//                            isFirst = NSNumber(value: Int(val as! String)!)
//                        }
//                        if let val = dict2["isLast"] {
//                            isLast = NSNumber(value: Int(val as! String)!)
//                        }
//                        if let val = dict2["isNoMid"] {
//                            isNoMid = NSNumber(value: Int(val as! String)!)
//                        }
//
//                        let tmp : NSNumber = NSNumber(value: Int(dict2["selectedOption"] as! String)!)
//                        if (tmp == 0){
//                            isSelectedAll = 1
//                            isAllDays = 1
//                        }else if (tmp == 2){
//                            isCalendar = 1
//                        }
//
//                        if let val = dict2["reportValue"] {
//                            reportValue = val as! String
//                        }
//                        if let val = dict2["releaseValue"] {
//                            releaseValue = val as! String
//                        }
//                        if let val = varb["selectedIndex"] as? [Int] {
//                            seletedIndices = val
//                        }
//
//                        let filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
//                        filterRule.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
//                        filterRule.abbreviation = (reportReleaseValueDict["Abbreviation"] as! String)
//                        filterRule.category = (reportReleaseValueDict["Category"] as! NSNumber)
//                        let typeInt = Int(reportReleaseValueDict["Type"] as! String)
//                        filterRule.type = NSNumber(integerLiteral: typeInt!) //(subFilter["Type"] as! NSNumber)
//                        filterRule.name = (reportReleaseValueDict["Name"] as! String)
//                        filterRule.keyPath = (reportReleaseValueDict["KeyPath"] as! String)
//                        filterRule.comparison = (reportReleaseValueDict["Comparison"] as! NSNumber)
//
//                        for index in seletedIndices {
//                            var strDay = String()
//                            self.configureMonthDayFilter(filterRule: filterRule, index: index, addDay: true)
//                            let day: BICalendarDay? = self.calendarData?.calendarDays[index] as? BICalendarDay
//                            if !(day?.isCurrentMonth)! {
//                                if self.bidPeriod?.month?.intValue == 12 {
//                                    let month: Int = 1
//                                    let year: Int = self.bidPeriod!.year!.intValue + 1
//                                    strDay = "\((day?.text)!)-\(month)-\(year)"
//                                } else {
//                                    strDay = "\((day?.text)!)-\((self.bidPeriod?.month?.intValue)! + 1)-\(self.bidPeriod!.year!.intValue)"
//                                }
//                            } else {
//                                strDay = "\((day?.text)!)-\((self.bidPeriod?.month)!)-\((self.bidPeriod?.year)!)"
//                            }
//                            seletedDates.append(strDay)
//                        }
//                        let variables = NSMutableDictionary()
//                        variables.setObject(seletedDates, forKey: BIFilterRuleSelectedDaysVariablesKey as NSCopying)
//                        let MONTH_BITS: UInt64 = filterRule.variables?["MONTH_BITS"] as? UInt64 ?? 0
//                        variables["MONTH_BITS"] = MONTH_BITS
//                        variables["isAllDays"] = isAllDays
//                        variables["isCalendar"] = isCalendar
//                        variables["isFirst"] = isFirst
//                        variables["isLast"] = isLast
//                        variables["isNoMid"] = isNoMid
//                        variables["isSelectedAll"] = isSelectedAll
//                        variables["releaseValue"] = releaseValue
//                        variables["reportValue"] = reportValue
//                        filterRule.variables = variables
//                        let reportReleaseVC = CBReportReleaseRuleCellTableViewCell()
//                        reportReleaseVC.bidPeriod = self.bidPeriod
//                        reportReleaseVC.filterRule = filterRule
//                        reportReleaseVC.calendarData = self.calendarData
//
//                        DispatchQueue.main.asyncAfter(deadline: .now()) {
//                            CBGlobalMethods.shared.showMBProgressHudOn(view: self.view, text: "Calculating  values..")
//                            CBGlobalMethods.shared.hud?.bezelView.color = UIColor(rgb: 0x035A01)
//                            CBGlobalMethods.shared.hud?.label.textColor = .white
//                        }
//
//                        if isAllDays.boolValue {
//                            reportReleaseVC.multiplReportReleaseAllDaysFromSync { completed in
//                                DispatchQueue.main.asyncAfter(deadline: .now()) {
//                                    CBGlobalMethods.shared.hud?.hide(animated: true)
//                                }
//                            }
//                        } else if (isFirst.boolValue || isLast.boolValue) && tmp == 1{
//                            reportReleaseVC.multiplReportReleaseFromSync { completed in
//                                DispatchQueue.main.asyncAfter(deadline: .now()) {
//                                    CBGlobalMethods.shared.hud?.hide(animated: true)
//                                }
//                            }
//                        } else if isCalendar.boolValue {
//                            reportReleaseVC.multiplReportReleaseDatesFromSync { completed in
//                                DispatchQueue.main.asyncAfter(deadline: .now()) {
//                                    CBGlobalMethods.shared.hud?.hide(animated: true)
//                                }
//                            }
//                        }else{
//                            DispatchQueue.main.asyncAfter(deadline: .now()) {
//                                CBGlobalMethods.shared.hud?.hide(animated: true)
//                            }
//                        }
//                    }
//                }
            }
        }
        
        do {
            try self.bidPeriod.managedObjectContext?.save()
        } catch {
            print(error)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    private func setQuickFilterToLocalDB(details: [String: Any]) {
        if let result = CBGlobalMethods.shared.selectedBidPeriod?.lineFilters?.allObjects as? [BIFilterRule] {
            for filterRule in result {
                self.bidPeriod.managedObjectContext?.delete(filterRule)
            }
        }
        
        // add default quickfilters
        // if lstQuickFiltersArray.count == 0 {
        // let biReader = BIBidInfoReader()
        // biReader.bidPeriod = bidPeriod
        // biReader.addDefaultFilterRules(self.bidPeriod.managedObjectContext)
        // return
        // }
        let lstQuickFilters = details
        let SET = NSMutableSet()
        var filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
        filterRule.bidPeriod = self.bidPeriod
        filterRule.category = 0
        if (self.bidPeriod.isEtopsLinesContainsInBid ?? 0).boolValue {
            // ETOPS
            if self.bidPeriod.isSecondRoundBid() {
                SET.add(7)
                SET.add(8)
                SET.add(4)
                if (lstQuickFilters["nonConUs"] as! Bool) == false {
                    SET.add(7)
                }
                if (lstQuickFilters["conUs"] as! Bool) == false {
                    SET.add(8)
                }
                if (lstQuickFilters["etops"] as! Bool) == false {
                    SET.add(9)
                }
            } else {
                if !self.bidPeriod.isFlightAttendantBid() {
                    // SET.add(13) // default filter values for query
                    //PILOT
                    SET.add(1)
                    SET.add(2)
                    SET.add(3)
                    SET.add(5)
                    SET.add(9)
                    SET.add(12)
                } else {
                    // default filter values for query
                    // FA
                    SET.add(1)
                    SET.add(2)
                    SET.add(13)
                }
                if (lstQuickFilters["nonConUs"] as! Bool) == false {
                    SET.add(7)
                }
                if (lstQuickFilters["conUs"] as! Bool) == false {
                    SET.add(8)
                }
                if (lstQuickFilters["blank"] as! Bool) == false {
                    SET.add(4)
                }
            }
            if (lstQuickFilters["reserve"] as! Bool) == false {
                SET.add(6)
            }
        } else {
            // Non ETOPS
            if self.bidPeriod.isSecondRoundBid() {
                SET.add(1)
                SET.add(2)
                SET.add(4)
                if !self.bidPeriod.isFlightAttendantBid() {
                    if (lstQuickFilters["hard"] as! Bool) == false {
                        SET.add(0)
                    }
                    if (lstQuickFilters["mixed"] as! Bool) == false {
                        SET.add(5)
                    }
                }
                if (lstQuickFilters["mixed"] as! Bool) == false {
                    SET.add(5)
                }
            } else {
                if (lstQuickFilters["conUs"] as! Bool) == false {
                    SET.add(1)
                }
                if (lstQuickFilters["nonConUs"] as! Bool) == false {
                    SET.add(2)
                }
                if (lstQuickFilters["blank"] as! Bool) == false {
                    SET.add(4)
                }
                if (lstQuickFilters["mixed"] as! Bool) == false {
                    SET.add(5)
                }
            }
            if (lstQuickFilters["reserve"] as! Bool) == false {
                SET.add(3)
            }
            
        }
        var dict  = NSDictionary(object: SET.mutableCopy(), forKey: "SET" as NSCopying)
        filterRule.variables = dict
        
        // For FA
        if (lstQuickFilters["posA"] != nil) && (self.bidPeriod.isFlightAttendantBid()) {
            SET.removeAllObjects()
            filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
            filterRule.bidPeriod = self.bidPeriod
            filterRule.category = 3
            if (lstQuickFilters["posA"] as! Bool) == false {
                SET.add(BIFaPosition.BIFaPositionA.rawValue)
            }
            if (lstQuickFilters["posB"] as! Bool) == false {
                SET.add(BIFaPosition.BIFaPositionB.rawValue)
            }
            if (lstQuickFilters["posC"] as! Bool) == false {
                SET.add(BIFaPosition.BIFaPositionC.rawValue)
            }
            if (lstQuickFilters["posD"] as! Bool) == false {
                SET.add(BIFaPosition.BIFaPositionD.rawValue)
            }
            if lstQuickFilters["posNA"] != nil {
                // sometime from web posNA will not be there
                // For handling the filter query posNA is reqired in iOS
                if (lstQuickFilters["posNA"] as! Bool) == false {
                    SET.add(BIFaPosition.BIFaPositionNA.rawValue)
                }
            }
            if (lstQuickFilters["posMultiple"] as! Bool) == false {
                SET.add(BIFaPosition.BIFaPositionMultiple.rawValue)
            }
            dict  = NSDictionary(object: SET.mutableCopy(), forKey: "SET" as NSCopying)
            filterRule.variables = dict
        }
        
        
        filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
        filterRule.bidPeriod = self.bidPeriod
        SET.removeAllObjects()
        filterRule.category = 35
        if (lstQuickFilters["etops"] as! Bool) == false {
            dict  = NSDictionary(object: 1, forKey: "ETOPS_ON" as NSCopying)
            filterRule.variables = dict
        } else {
            dict  = NSDictionary(object: 0, forKey: "ETOPS_ON" as NSCopying)
            filterRule.variables = dict
        }
        
        
        filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
        filterRule.bidPeriod = self.bidPeriod
        filterRule.category = 38
        if (lstQuickFilters["etopsRes"] as! Bool) == false {
            dict  = NSDictionary(object: 1, forKey: "ETOPSRES_ON" as NSCopying)
            filterRule.variables = dict
        } else {
            dict  = NSDictionary(object: 0, forKey: "ETOPSRES_ON" as NSCopying)
            filterRule.variables = dict
        }
        
        if self.bidPeriod.isFlightAttendantBid() && self.bidPeriod.isSecondRoundBid() {
            filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
            filterRule.bidPeriod = self.bidPeriod
            filterRule.category = 2
            if (lstQuickFilters["amReserve"] as? Bool ?? false) == false {
                SET.add(BIFaReserveLineType.BIFaReserveLineTypeAmReserve.rawValue)
            }
            if (lstQuickFilters["pmReserve"] as? Bool ?? false) == false {
                SET.add(BIFaReserveLineType.BIFaReserveLineTypePmReserve.rawValue)
            }
            if (lstQuickFilters["readyReserve"] as? Bool ?? false) == false {
                SET.add(BIFaReserveLineType.BIFaReserveLineTypeReadyReserve.rawValue)
            }
            if (lstQuickFilters["noReserve"] as? Bool ?? false) == false {
                SET.add(BIFaReserveLineType.BIFaReserveLineTypeNoType.rawValue)
            }
            dict  = NSDictionary(object: SET.mutableCopy(), forKey: "SET" as NSCopying)
            filterRule.variables = dict
        }
        
        filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
        filterRule.bidPeriod = self.bidPeriod
        SET.removeAllObjects()
        filterRule.category = 1
        SET.add(3)
        if (lstQuickFilters["amLines"] as! Bool) == false {
            SET.add(0)
        }
        if (lstQuickFilters["mixedLines"] as! Bool) == false {
            SET.add(1)
        }
        if (lstQuickFilters["pmLines"] as! Bool) == false {
            SET.add(2)
        }
        dict  = NSDictionary(object: SET.mutableCopy(), forKey: "SET" as NSCopying)
        filterRule.variables = dict
        
        
        filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
        filterRule.bidPeriod = self.bidPeriod
        filterRule.category = 4
        var mask: Int = 0
        var weekdayBits = 0
        if (lstQuickFilters["sun"] as! Bool) == true {
            mask = 1 << 0
            weekdayBits |= mask
        }
        if (lstQuickFilters["mon"] as! Bool) == true {
            mask = 1 << 1
            weekdayBits |= mask
        }
        if (lstQuickFilters["tue"] as! Bool) == true {
            mask = 1 << 2
            weekdayBits |= mask
        }
        if (lstQuickFilters["wed"] as! Bool) == true {
            mask = 1 << 3
            weekdayBits |= mask
        }
        if (lstQuickFilters["thu"] as! Bool) == true {
            mask = 1 << 4
            weekdayBits |= mask
        }
        if (lstQuickFilters["fri"] as! Bool) == true {
            mask = 1 << 5
            weekdayBits |= mask
        }
        if (lstQuickFilters["sat"] as! Bool) == true {
            mask = 1 << 6
            weekdayBits |= mask
        }
        // weekdayBits |= mask
        dict  = NSDictionary(object: weekdayBits, forKey: "WEEKDAY_BITS" as NSCopying)
        filterRule.variables = dict
        do {
            try self.bidPeriod.managedObjectContext?.save()
        } catch {
            print(error)
        }
        
        
        filterRule = NSEntityDescription.insertNewObject(forEntityName: BIFilterRuleEntityName, into: self.bidPeriod.managedObjectContext!) as! BIFilterRule
        filterRule.bidPeriod = self.bidPeriod
        let dictMutable = NSMutableDictionary()
        filterRule.category = 5
        if (lstQuickFilters["turns"] as! Bool) == false {
            dictMutable.setObject(1, forKey: "TURNS_ON" as NSCopying)
            filterRule.variables = dictMutable
        } else {
            dictMutable.setObject(0, forKey: "TURNS_ON" as NSCopying)
            filterRule.variables = dictMutable
        }
        
        if (lstQuickFilters["twoDays"] as! Bool) == false {
            dictMutable.setObject(1, forKey: "TWO_DAYS_ON" as NSCopying)
            filterRule.variables = dictMutable
        } else {
            dictMutable.setObject(0, forKey: "TWO_DAYS_ON" as NSCopying)
            filterRule.variables = dictMutable
        }
        
        if (lstQuickFilters["threeDays"] as! Bool) == false {
            dictMutable.setObject(1, forKey: "THREE_DAYS_ON" as NSCopying)
            filterRule.variables = dictMutable
        } else {
            dictMutable.setObject(0, forKey: "THREE_DAYS_ON" as NSCopying)
            filterRule.variables = dictMutable
        }
        
        if (lstQuickFilters["fourDays"] as! Bool) == false {
            dictMutable.setObject(1, forKey: "FOUR_DAYS_ON" as NSCopying)
            filterRule.variables = dictMutable
        } else {
            dictMutable.setObject(0, forKey: "FOUR_DAYS_ON" as NSCopying)
            filterRule.variables = dictMutable
        }
        
        do {
            try self.bidPeriod.managedObjectContext?.save()
        } catch {
            print(error)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func getPresetDict() -> Dictionary<String, Any>{
        var filterSortState : Dictionary = Dictionary<String, Any>()
        filterSortState["lstQuickFilters"] = self.getQuickFilterList()["lstQuickFilters"]
        filterSortState["lstSorts"] = self.getMenuSortListDict()["lstSorts"]
        filterSortState["lstFilters"] = self.getMenuFilterListDict()["lstFilters"]
        return filterSortState
    }
    
    
    // parse quick filter from filterRules
    private func getQuickFilterList() -> [String: Any] {
        var dict = self.getQuickFilterDefaultDict()
        if let resultsPresetFilter = CBGlobalMethods.shared.selectedBidPeriod!.lineFilters?.allObjects as? [BIFilterRule] {
            for i in 0 ..< resultsPresetFilter.count {
                if resultsPresetFilter[i].abbreviation == nil {
                    let filter = resultsPresetFilter[i]
                    if filter.category?.intValue == BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue {
                        let SET = filter.variables!["SET"] as! NSSet
                        let valArray = SET.allObjects as! [Int]
                        if valArray.contains(BILineType.BILineTypeNonEtopsConUs.rawValue) {
                            dict["conUs"] = false
                        } else {
                            dict["conUs"] = true
                        }
                        if valArray.contains(BILineType.BILineTypeNonEtopsNonConUs.rawValue) {
                            dict["nonConUs"] = false
                        } else {
                            dict["nonConUs"] = true
                        }
                        if valArray.contains(BILineType.BIReserveLineType.rawValue) {
                            dict["reserve"] = false
                        } else {
                            dict["reserve"] = true
                        }
                        if valArray.contains(BILineType.BIBlankLineType.rawValue) {
                            dict["blank"] = false
                        } else {
                            dict["blank"] = true
                        }
                    }
                    else if filter.category?.intValue == BIFilterRuleCategory.BIEtopsFilterRuleCategory.rawValue {
                        let val = filter.variables!["ETOPS_ON"] as! NSNumber
                        if val.intValue == 1 {
                            dict["etops"] = false
                        } else {
                            dict["etops"] = true
                        }
                    }
                    else if filter.category?.intValue == BIFilterRuleCategory.BIEtopsResFilterRuleCategory.rawValue {
                        let val = filter.variables!["ETOPSRES_ON"] as! NSNumber
                        if val.intValue == 1 {
                            dict["etopsRes"] = false
                        } else {
                            dict["etopsRes"] = true
                        }
                    }
                    else if filter.category?.intValue == BIFilterRuleCategory.BIAmPmFilterRuleCategory.rawValue {
                        let SET = filter.variables!["SET"] as! NSSet
                        
                        let varArray = SET.allObjects as! [Int]
                        if varArray.contains(BILineAmPm.BIAmLine.rawValue) {
                            dict["amLines"] = false
                        } else {
                            dict["amLines"] = true
                        }
                        if varArray.contains(BILineAmPm.BIMixedAmPmLine.rawValue) {
                            dict["mixedLines"] = false
                        } else {
                            dict["mixedLines"] = true
                        }
                        if varArray.contains(BILineAmPm.BIPmLine.rawValue) {
                            dict["pmLines"] = false
                        } else {
                            dict["pmLines"] = true
                        }
                    }
                    else if filter.category?.intValue == BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue {
                        let SET = filter.variables!["SET"] as! NSSet
                        let varArray = SET.allObjects as! [Int]
                        
                        if varArray.contains(BIFaPosition.BIFaPositionA.rawValue) { //1
                            dict["posA"] = false
                        } else {
                            dict["posA"] = true
                        }
                        if varArray.contains(BIFaPosition.BIFaPositionB.rawValue) { //2
                            dict["posB"] = false
                        } else {
                            dict["posB"] = true
                        }
                        if varArray.contains(BIFaPosition.BIFaPositionC.rawValue) { //3
                            dict["posC"] = false
                        } else {
                            dict["posC"] = true
                        }
                        if varArray.contains(BIFaPosition.BIFaPositionD.rawValue) { //4
                            dict["posD"] = false
                        } else {
                            dict["posD"] = true
                        }
                        if varArray.contains(BIFaPosition.BIFaPositionMultiple.rawValue) { //5
                            dict["posMultiple"] = false
                        } else {
                            dict["posMultiple"] = true
                        }
                        if varArray.contains(BIFaPosition.BIFaPositionNA.rawValue) { //6
                            dict["posNA"] = false
                        } else {
                            dict["posNA"] = true
                        }
                    }
                    else if filter.category?.intValue == BIFilterRuleCategory.BIDaysOfWeekFilterRuleCategory.rawValue {
                        let weekdayBits: Int = Int(truncating: filter.variables?["WEEKDAY_BITS"]! as! NSNumber)
                        for wkday in 0..<7 {
                            let bitSet: Int = weekdayBits & (1 << wkday)
                            let select: Bool = bitSet == 0
                            switch wkday {
                            case 0:
                                dict["sun"] = !select
                            case 1:
                                dict["mon"] = !select
                            case 2:
                                dict["tue"] = !select
                            case 3:
                                dict["wed"] = !select
                            case 4:
                                dict["thu"] = !select
                            case 5:
                                dict["fri"] = !select
                            case 6:
                                dict["sat"] = !select
                            default:
                                break
                            }
                        }
                    }
                    else if filter.category?.intValue == BIFilterRuleCategory.BITripLengthFilterRuleCategory.rawValue {
                        let TURNS_ON = filter.variables!["TURNS_ON"] as! NSNumber
                        if TURNS_ON.intValue == 0 {
                            dict["turns"] = true
                        }
                        let TWO_DAYS_ON = filter.variables!["TWO_DAYS_ON"] as! NSNumber
                        if TWO_DAYS_ON.intValue == 0 {
                            dict["twoDays"] = true
                        }
                        let THREE_DAYS_ON = filter.variables!["THREE_DAYS_ON"] as! NSNumber
                        if THREE_DAYS_ON.intValue == 0 {
                            dict["threeDays"] = true
                        }
                        let FOUR_DAYS_ON = filter.variables!["FOUR_DAYS_ON"] as! NSNumber
                        if FOUR_DAYS_ON.intValue == 0 {
                            dict["fourDays"] = true
                        }
                    }
                }
            }
        }
        let dictArray = [dict]
        let LstQuickFiletDict: [String: Any] = ["lstQuickFilters" : dictArray]
        return LstQuickFiletDict
    }
    
    
    private func getQuickFilterDefaultDict() -> [String: Any] {
        var dict = [String: Any]()
        if self.bidPeriod.isFlightAttendantBid() {
            dict = [
                "mixed": false,
                "conUs": false,
                "nonConUs": false,
                "reserve": false,
                "blank": false,
                "etops": false,
                "etopsRes": false,
                "amLines": false,
                "pmLines": false,
                "mixedLines": false,
                "posA": false,
                "posB": false,
                "posC": false,
                "posD": false,
                "posMultiple": false,
                "posNA": false,
                "sun": false,
                "mon": false,
                "tue": false,
                "wed": false,
                "thu": false,
                "fri": false,
                "sat": false,
                "turns": false,
                "twoDays": false,
                "threeDays": false,
                "fourDays": false
            ]
        } else {
            dict = [
                "mixed": false,
                "hard": false,
                "conUs": false,
                "nonConUs": false,
                "reserve": false,
                "blank": false,
                "etops": false,
                "etopsRes": false,
                "amLines": false,
                "pmLines": false,
                "mixedLines": false,
                "sun": false,
                "mon": false,
                "tue": false,
                "wed": false,
                "thu": false,
                "fri": false,
                "sat": false,
                "turns": false,
                "twoDays": false,
                "threeDays": false,
                "fourDays": false
            ]
        }
        return dict
    }
    
    
    
    // parse menu sort from lineSort
    private func getMenuSortListDict() -> [String: Any] {
        var sortsList = [[String: Any]]()
        var currentTitle = ""
        var listSortArray = [[String: Any]]()
        var ListSortDict = [String: Any]()
        var DefaultCommutingValues : [String: Any]? = nil
        if let resultsPresetSort = CBGlobalMethods.shared.selectedBidPeriod?.lineSorts?.allObjects as? [BILineSort] {
            for i in 0 ..< resultsPresetSort.count {
                let sort = resultsPresetSort[i]
                currentTitle = sortTitleDict[resultsPresetSort[i].abbreviation!]!
                var dict = [String: Any]()
                dict["Abbreviation"] = sort.abbreviation
                dict["Category"] = sort.category
                if sort.type != nil {
                    dict["Type"] = sort.type
                }
                if sort.arrayVariables != nil {
                    dict["ArrayVariables"] = sort.arrayVariables
                }
                dict["Order"] = sort.order
                dict["Name"] = sort.name
                dict["KeyPath"] = sort.keyPath
                dict["Ascending"] = sort.ascending?.boolValue
                var variables : [String : Any] = [:]
                
                if sort.abbreviation == "OffSort" || sort.abbreviation == "WorkSort" || sort.abbreviation == "TripStartSort" {
                    var variable = [Int]()
                    for index in 0 ..< calendarData.calendarDays.count {
                        let monthBits: UInt64 = sort.variables!["DAYS_OFF_MONTH_BITS"] as! CUnsignedLongLong
                        let one: UInt64 = 1
                        var mask: UInt64 = 0
                        mask = one << index
                        if monthBits & mask != 0 {
                            variable.append(index)
                        }
                    }
                    dict["ArrayVariables"] = variable
                }
                
                else if sort.abbreviation == "CmAuto"{
//                    var dict2 = [String: Any]()
//                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
//                    let entity = NSEntityDescription.entity(forEntityName: "Commutability", in: (linesManager?.managedObjectContext)!)
//                    fetchRequest.entity = entity
//                    fetchRequest.predicate = NSPredicate(format: "commutableType == 1")
//                    let fetchedObjects = try! bidPeriod?.managedObjectContext!.fetch(fetchRequest) as! [Commutability]
//                    var Objcommutability: Commutability?
//                    if fetchedObjects.count > 0 {
//                        Objcommutability = fetchedObjects[0]
//                        dict2["commuteCity"] = Objcommutability!.city!
//                        dict2["selectedConnectTime"] = self.getHoursFrom(minutes: Objcommutability!.connectTime!)
//                        dict2["selectedTakeOffPadTimeValues"] = self.getHoursFrom(minutes: Objcommutability!.checkInTime!)
//                        dict2["selectedBackToBasePadTimeValues"] = self.getHoursFrom(minutes: Objcommutability!.baseTime!)
//                        dict2["nonStop"] = Objcommutability!.isNonStop!.boolValue
//                        dict2["cmtFrBaOv"] = Objcommutability!.thirdCellValue!.stringValue
//                        dict2["nMid"] = Objcommutability!.secondCellValue!.stringValue
//                        dict2["cmtGreaterOrLesser"] = Objcommutability!.type!.stringValue
//                        dict2["cmtPercentage"] = Objcommutability!.value!.stringValue
//                        dict["Variable"] = dict2
//                    }
                }
                
                else if sort.abbreviation == "Commute" { // Commuting Manual
                    let variable = sort.variables as! [String: Any]
                    var dict2 = [String: Any]()
                    // Converting all elements in the variable dict to String objects
                    variable.forEach { dict2[$0.0] = String(describing: $0.1) }
                    
                    for (key, val) in dict2 {
                        if val as! String == "-1" || val as! String  == "3000" {
                            dict2[key] = ""
                        }
                    }
                    
                    variables = [
                        "MON_THURS_DEPART" : dict2["MON_THURS_DEPART"] as! String,
                        "MON_THURS_RETURN" : dict2["MON_THURS_RETURN"] as! String,
                        "FRI_RETURN" : dict2["FRI_RETURN"] as! String,
                        "FRI_DEPART" : dict2["FRI_DEPART"] as! String,
                        "SAT_DEPART" : dict2["SAT_DEPART"] as! String,
                        "SAT_RETURN" : dict2["SAT_RETURN"] as! String,
                        "SUN_DEPART" : dict2["SUN_DEPART"] as! String,
                        "SUN_RETURN" : dict2["SUN_RETURN"] as! String,
                        "NoMidCheckState" :  (NSNumber(integerLiteral: Int(dict2["NoMidCheckState"] as! String)!)).boolValue]
                    dict["Variable"] = variables
                    let defaultCommuteTimes = UserDefaults.standard.array(forKey: kCBDefaultCommutingTimesKey)
                    if defaultCommuteTimes != nil {
                        let monThursDept = defaultCommuteTimes![0] as! Int
                        let monThursRet = defaultCommuteTimes![1] as! Int
                        let friDept = defaultCommuteTimes![2] as! Int
                        let friRet = defaultCommuteTimes![3] as! Int
                        let satDept = defaultCommuteTimes![4] as! Int
                        let satRet = defaultCommuteTimes![5] as! Int
                        let sunDept = defaultCommuteTimes![6] as! Int
                        let sunRet = defaultCommuteTimes![7] as! Int
                        
                        DefaultCommutingValues = [String: Any]()
                        
                        DefaultCommutingValues!["MON_THURS_DEPART"] = String(monThursDept)
                        DefaultCommutingValues!["MON_THURS_RETURN"] = String(monThursRet)
                        DefaultCommutingValues!["FRI_DEPART"] = String(friDept)
                        DefaultCommutingValues!["FRI_RETURN"] = String(friRet)
                        DefaultCommutingValues!["SAT_DEPART"] = String(satDept)
                        DefaultCommutingValues!["SAT_RETURN"] = String(satRet)
                        DefaultCommutingValues!["SUN_DEPART"] = String(sunDept)
                        DefaultCommutingValues!["SUN_RETURN"] = String(sunRet)
                        DefaultCommutingValues!["NoMidCheckState"] = false
                    }
                }
                else if currentTitle == "Regional Overnight Cities" {
                    dict["Variable"] = ["CITY": ((sort.variables as! [String: Any])["SET"] as! NSSet).allObjects]
                } else {
                    dict["Variable"] = sort.variables
                }
                dict["IsMutable"] = sort.isMutable
                if sort.city != nil {
                    dict["City"] = sort.city
                }
                listSortArray.append(dict)
               
                if i == resultsPresetSort.count - 1 || resultsPresetSort[i + 1].abbreviation == nil || currentTitle != sortTitleDict[resultsPresetSort[i + 1].abbreviation!] {
                    ListSortDict["title"] = sortTitleDict[sort.abbreviation!]
                    ListSortDict["ListSort"] = listSortArray
                    sortsList.append(ListSortDict)
                    listSortArray.removeAll()
                }
            }
        }
        var lstSortDict: [String: Any] = ["lstSorts" : sortsList]
        if DefaultCommutingValues != nil {
            lstSortDict["DefaultCommutingValues"] = DefaultCommutingValues!
        }
        return lstSortDict
    }
    
    
    // parse menu filter from filterRules
    private func getMenuFilterListDict() -> [String: Any] {
        var FiltersList = [[String: Any]]()
        var currentTitle = ""
        var listFilterArray = [[String: Any]]()
        var ListFilterDict = [String: Any]()
        if let resultsPresetFilter = CBGlobalMethods.shared.selectedBidPeriod!.lineFilters?.allObjects as? [BIFilterRule] {
            for i in 0 ..< resultsPresetFilter.count {
                if resultsPresetFilter[i].abbreviation != nil {
                    let filter = resultsPresetFilter[i]
                    var dict = [String: Any]()
                    
                    dict["Abbreviation"] = filter.abbreviation
                    dict["Category"] = filter.category
                    dict["Type"] = filter.type?.stringValue
                    dict["Name"] = filter.name
                    dict["KeyPath"] = filter.keyPath
                    dict["Comparison"] = filter.comparison
                    var variables = filter.variables as Any
                    if filter.abbreviation == "Flags" {
                        variables = ((filter.variables as! [String: Any])["SET"] as! NSSet).allObjects
                    }
                    else if filter.abbreviation == "WantDays" || filter.abbreviation == "MonthDays" || filter.abbreviation == "TripStarts" {
                        var variable = [Int]()
                        for index in 0 ..< calendarData.calendarDays.count {
                            let monthBits: UInt64 = filter.variables!["MONTH_BITS"] as! CUnsignedLongLong
                            let one: UInt64 = 1
                            var mask: UInt64 = 0
                            mask = one << index
                            if monthBits & mask != 0 {
                                variable.append(index)
                            }
                        }
                        variables = variable
                    }else if filter.abbreviation == "CmAuto"{
//                        let variable = variables as! [String: Any]
//                        var dict2 = [String: Any]()
//                        variable.forEach { dict2[$0.0] = String(describing: $0.1) }
//                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
//                        let entity = NSEntityDescription.entity(forEntityName: "Commutability", in: (linesManager?.managedObjectContext)!)
//                        fetchRequest.entity = entity
//                        fetchRequest.predicate = NSPredicate(format: "commutableType == 0")
//                        let fetchedObjects = try! self.bidPeriod?.managedObjectContext!.fetch(fetchRequest) as! [Commutability]
//                        var Objcommutability: Commutability?
//                        if fetchedObjects.count > 0 {
//                            Objcommutability = fetchedObjects[0]
//                            variables = ["commuteCity" : Objcommutability!.city!,
//                                         "selectedConnectTime" : self.getHoursFrom(minutes: Objcommutability!.connectTime!),
//                                         "nonStop" : Objcommutability!.isNonStop!.boolValue,
//                                         "selectedTakeOffPadTimeValues" : self.getHoursFrom(minutes: Objcommutability!.checkInTime!),
//                                         "selectedBackToBasePadTimeValues" : self.getHoursFrom(minutes: Objcommutability!.baseTime!),
//                                         "nMid" : Objcommutability!.secondCellValue!.stringValue,
//                                         "cmtFrBaOv" : Objcommutability!.thirdCellValue!.stringValue,
//                                         "cmtGreaterOrLesser" : Objcommutability!.type!.stringValue,
//                                         "cmtPercentage" : Objcommutability!.value!.stringValue]
//                        }
//                        dict["Variable"] = variables
                    } else if filter.abbreviation == "CRqd" { // Commuting Manual
                        let variable = variables as! [String: Any]
                        var dict2 = [String: Any]()
                        // Converting all elements in the variable dict to String objects
                        variable.forEach { dict2[$0.0] = String(describing: $0.1) }
                        for (key, val) in dict2 {
                            if val as! String == "-1" || val as! String  == "3000" {
                                dict2[key] = ""
                            }
                        }
                        variables = ["RANGEEND" : dict2["RANGEEND"] as! String,
                                     "RANGESTART" : dict2["RANGESTART"] as! String,
                                     "MON_THURS_DEPART" : dict2["MON_THURS_DEPART"] as! String,
                                     "MON_THURS_RETURN" : dict2["MON_THURS_RETURN"] as! String,
                                     "FRI_RETURN" : dict2["FRI_RETURN"] as! String,
                                     "FRI_DEPART" : dict2["FRI_DEPART"] as! String,
                                     "SAT_DEPART" : dict2["SAT_DEPART"] as! String,
                                     "SAT_RETURN" : dict2["SAT_RETURN"] as! String,
                                     "SUN_DEPART" : dict2["SUN_DEPART"] as! String,
                                     "SUN_RETURN" : dict2["SUN_RETURN"] as! String,
                                     "VALUE" : dict2["VALUE"] as! String,
                                     "NoMidCheckState" :  (NSNumber(integerLiteral: Int(dict2["NoMidCheckState"] as! String)!)).boolValue]
                        dict["Variable"] = variables
                    } else if filter.abbreviation == "Report-Release" { //Report-Release Filter
                        dict["Abbreviation"] = "Report-Release"
                        var variables = [String: Any]()
                        let dict2 = filter.variables
                        
                        var selectedIndices = [Int]()
                        
                        for index in 0...calendarData.calendarDays.count{
                            
                            let monthBits: UInt64 = filter.variables!["MONTH_BITS"] as! CUnsignedLongLong
                            let one: UInt64 = 1
                            var mask: UInt64 = 0
                            mask = one << index
                            if monthBits & mask != 0 {
                                selectedIndices.append(index)
                            }
                        }
                          
                        variables["selectedIndex"] = selectedIndices
                        variables["selectedOption"] = 1
                        if dict2!["isFirst"] != nil {
                            let tmp = dict2!["isFirst"] as? Int ?? 0
                            variables["isFirst"] = tmp
                        }else{
                            variables["isFirst"] = 0
                        }
                        
                        if dict2!["isLast"] != nil {
                            let tmp = dict2!["isLast"] as? Int ?? 0
                            variables["isLast"] = tmp
                        }else{
                            variables["isLast"] = 0
                        }
                        
                        if dict2!["isNoMid"] != nil {
                            let tmp = dict2!["isNoMid"] as? Int ?? 0
                            variables["isNoMid"] = tmp
                        }else{
                            variables["isNoMid"] = 0
                        }
                        
                        if dict2!["isCalendar"] != nil {
                            let tmp = dict2!["isCalendar"] as? Int ?? 0
                            variables["isCalendar"] = tmp
                            if tmp.boolValue{
                                variables["selectedOption"] = 2
                            }
                        }else{
                            variables["isCalendar"] = 0
                        }
                        
                        if dict2!["isAllDays"] != nil {
                            let tmp = dict2!["isAllDays"] as? Int ?? 0
                            variables["isAllDays"] = tmp
                            if tmp.boolValue{
                                variables["selectedOption"] = 0
                            }
                        }else{
                            variables["isAllDays"] = 0
                        }
                        
                        if dict2!["releaseValue"] != nil {
                            variables["releaseValue"] = dict2!["releaseValue"]!
                        }
                        
                        if dict2!["reportValue"] != nil {
                            variables["reportValue"] = dict2!["reportValue"]!
                        }
                        
                        dict["Variable"] = variables
                        
                    } else if filter.abbreviation == "OCB" {
                        let varb = filter.variables
                        var dict2 = [String: String]()
                        // Converting all elements in the variable dict to String objects
                        varb!.forEach { dict2[$0.0 as! String] = String(describing: $0.1) }
                        filter.variables = dict2 as NSDictionary
                        //let variable = filter.variables
                        let overnightNoCitiesArray = [String]()
                        let overnightYesCitiesArray = [String]()
                        let variables = ["OverNightYes": overnightYesCitiesArray, "OverNightNo": overnightNoCitiesArray]
                        dict["Variable"] = variables
                    }
                    
                    dict["Variable"] = variables
                    listFilterArray.append(dict)
                    currentTitle = filterTitleDict[resultsPresetFilter[i].abbreviation!]!
                    if i == resultsPresetFilter.count - 1 || resultsPresetFilter[i + 1].abbreviation == nil || currentTitle != filterTitleDict[resultsPresetFilter[i + 1].abbreviation!] {
                        ListFilterDict["title"] = filterTitleDict[filter.abbreviation!]
                        ListFilterDict["Listfilter"] = listFilterArray
                        FiltersList.append(ListFilterDict)
                        listFilterArray.removeAll()
                    }
                }
            }
        }
        let LstFiletDict: [String: Any] = ["lstFilters" : FiltersList]
        return LstFiletDict
    }
    
}


// This dict is for identifying the values from web and taking corresponding value in iOS.
let sortTitleDict = [
    "A" : "Position",
    "AllC" : "Regional Overnight Cities",
    "TripStartSort" : "Days of the Month Off",
    "WorkSort" : "Days of the Month Off",
    "B" : "Position",
    "BlkHrs" : "Block Hours",
    "BlkOff" : "Block of Days Off",
    "C" : "Position",
    "Chngs":"Aircraft Changes",
    "CmAuto" : "Commuting",
    "CoPay" : "Pay",
    "Commute" : "Commuting",
    "DHs" : "Deadheads",
    "DH Either": "Deadheads",
    "DH End" : "Deadheads",
    "DH Start" : "Deadheads",
    "Dty" : "Duty Time",
    "Dty/Day" : "Duty Time",
    "EC" : "Regional Overnight Cities",
    "EDep": "Earliest Departure",
    "eTops": "ETOPS",
    "flag" : "Flags",
    "Hawaii" : "Regional Overnight Cities",
    "LArr" : "Latest Arrival",
    "Legs" : "Legs",
    "Legs Thru" : "Cities",
    "linerig" : "Pay",
    "maxNite" : "Overnight Length",
    "MidPTBs" : "Passes through Base",
    "minNite" : "Overnight Length",
    "MLegs" : "Max Legs in a Day",
    "NonConLegs" : "Cities",
    "NonConUS" : "Regional Overnight Cities",
    "OCB" : "Cities",
    "Off" : "Days Off",
    "OffSort" : "Days of the Month Off",
    "OIBs" : "Overnights in Base",
    "OLap" : "Overlap Days",
    "Overnight City" : "Cities",
    "OvernightCity" : "Cities",
    "Pay" : "Pay",
    "PTBs" : "Passes through Base",
    "$/Blk" : "Pay",
    "$/Day" : "Pay",
    "$/Duty" : "Pay",
    "$/Leg" : "Pay",
    "$/Tafb" : "Pay",
    "700s" : "Aircraft Types",
    "800s": "Aircraft Types",
    "Max": "Aircraft Types",
    "8Max": "Aircraft Types",
    "7Max": "Aircraft Types",
    "PM": "AM/PM",
    "WC" : "Regional Overnight Cities",
    "Wknds" : "Days of Week",
    "Su" : "Days of Week",
    "Mo" : "Days of Week",
    "Tu" : "Days of Week",
    "Wed" : "Days of Week",
    "Th" : "Days of Week",
    "Fr" : "Days of Week",
    "Sa" : "Days of Week",
    "TAFB" : "TAFB",
    "Turns" : "Trip Length",
    "2Days" : "Trip Length",
    "3Days" : "Trip Length",
    "4Days" : "Trip Length",
    "Trips" : "Trips",
    "TpL" : "Vac+LG",
    "Work" : "Work Days",
    "vTotalPay" : "Vacation",
    "vFlyPay" : "Vacation",
    "vVacationPay": "Vacation",
    "v$/blk" : "Vacation",
    "v$/day" : "Vacation",
    "vCarryPay": "Vacation",
    "vCOutVOPay" : "Vacation",
    "vBlk" : "Vacation",
    "vOff": "Vacation",
    "vVacayLength" : "Vacation",
    "vLongest" : "Vacation",
    "vVOutPay": "Vacation",
    "vFrontVO" : "Vacation",
    "vBackVO": "Vacation",
]

// This dict is for identifying the values from web and taking corresponding value in iOS.
let filterTitleDict = [
    "Chngs" : "Aircraft Changes",
    "700s": "Aircraft Types",
    "800s": "Aircraft Types",
    "8Max": "Aircraft Types",
    "7Max": "Aircraft Types",
    "BlkOff" : "Block of Days Off",
    "BlkHrs" : "Block Hours",
    "OC" : "Cities",
    "OCB" : "Cities",
    "NonConLegs" : "Cities",
    "LegCty" : "Cities",
    "EC" : "Regional Overnight Cities",
    "WC" : "Regional Overnight Cities",
    "NonConUS" : "Regional Overnight Cities",
    "AllC" : "Regional Overnight Cities",
    "Hawaii" : "Regional Overnight Cities",
    "CRqd" : "Commuting",
    "CmAuto" : "Commuting",
    "MonthDays" : "Days of the Month",
    "WantDays" : "Days of the Month",
    "TripStarts" : "Days of the Month",
    "Off" : "Days Off",
    "Wknds" : "Days of Week",
    "Su" : "Days of Week",
    "Mo" : "Days of Week",
    "Tu" : "Days of Week",
    "Wed" : "Days of Week",
    "Th" : "Days of Week",
    "Fr" : "Days of Week",
    "Sa" : "Days of Week",
    "DHs" : "Deadheads",
    "DH Start" : "Deadheads",
    "DH End" : "Deadheads",
    "DH Either": "Deadheads",
    "DtyHrs" : "Duty Time",
    "Dty/Day" : "Duty Time",
    "Flags" : "Flags",
    "Legs" : "Legs",
    "MLegs" : "Max Legs in a Day",
    "StartOLap" : "Overlap Days",
    "EndOLap" : "Overlap Days",
    "OLength" : "Overnight Length",
    "OIBs" : "Overnights in Base",
    "PTBs" : "Passes Through Base",
    "MidPTBs" : "Passes Through Base",
    "Pay" : "Pay",
    "$/Blk" : "Pay",
    "$/Day" : "Pay",
    "$/Duty" : "Pay",
    "$/Leg" : "Pay",
    "$/Tafb" : "Pay",
    "CoPay" : "Pay",
    "Line Rig" : "Pay",
    "Report-Release" : "Report-Release",
    "TAFB" : "TAFB Hours",
    "Trips" : "Number of Trips",
    "Turns" : "Trip Length",
    "2Days" : "Trip Length",
    "3Days" : "Trip Length",
    "4Days" : "Trip Length",
    "Work" : "Workdays",
    "workBlock" : "WorkBlocks",
    
    // vacation filter
    "vTotalPay" : "Vacation",
    "vFlyPay" : "Vacation",
    "vVacPay": "Vacation",
    "v$/blk" : "Vacation",
    "v$/day" : "Vacation",
    "vCarryPay": "Vacation",
    "vCOutVOPay" : "Vacation",
    "vBlk" : "Vacation",
    "vOff": "Vacation",
    "vVacayLength" : "Vacation",
    "vLongest" : "Vacation",
    "vVOutPay": "Vacation",
    "vFrontVO" : "Vacation",
    "vBackVO": "Vacation"
]
