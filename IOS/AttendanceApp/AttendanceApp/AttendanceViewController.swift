

import UIKit
import FirebaseDatabase
import FirebaseAuth

class AttendanceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var ref: DatabaseReference!
    var clockInOut : String = "out"
    var postList = [Post]()
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "날짜"
        label.font = .systemFont(ofSize: 24, weight: .light)
        return label
    }()
    
    private let button: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.setTitle("출근하기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 30)
        button.layer.cornerRadius = 125
        return button
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private let logoutBtn: UIButton = {
        let button = UIButton()
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitle("로그아웃", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(label)
        view.addSubview(button)
        view.addSubview(tableView)
        view.addSubview(logoutBtn)
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        
        button.addTarget(self, action: #selector(clockInOutBtnTapped), for: .touchUpInside)
        logoutBtn.addTarget(self, action: #selector(logOutTapped), for: .touchUpInside)
        tableView.delegate = self
        tableView.dataSource = self
        
        ref = Database.database().reference()
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let query = ref.child("attendance").child(userID).child("ClockInOut").queryOrdered(byChild: "date")
        query.observe(.value, with: { snapshot in
            if snapshot.childrenCount > 0 {
                
                self.postList.removeAll()
                for child in snapshot.children {
                    let childSnap = child as! DataSnapshot
                    let dict = childSnap.value as! [String: Any]
                    let date = dict["date"] as! String
                    let inOut = dict["inout"] as! String
                    print(childSnap.key, date, inOut)
                    
                    let post = Post(date: date, inOut: inOut)
                    self.postList.append(post)
                }
                self.tableView.reloadData()
                
                self.clockInOut = self.postList.last!.inOut
                self.updateButtonUI()
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        label.frame = CGRect(x: 0, y: 80, width: view.frame.size.width, height: 20)
        
        button.frame = CGRect(x: view.frame.size.width/2 - 125,
                              y: label.frame.origin.y+label.frame.size.height+20,
                              width: 250,
                              height: 250)
        
        tableView.frame = CGRect(x: view.frame.size.width/2 - 150,
                                 y: button.frame.origin.y+button.frame.size.height+30,
                                 width: 300 ,
                                 height: 370)
        
        logoutBtn.frame = CGRect(x: 20,
                                 y: tableView.frame.origin.y+tableView.frame.size.height+20,
                                 width: view.frame.size.width-40,
                                 height: 52)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        for subView in cell.contentView.subviews{
                        subView .removeFromSuperview()
                    }
        
        let listItemLabel = UILabel()
        let inoutText = (postList[indexPath.row].inOut == "in") ? "출근" : "퇴근"
        listItemLabel.clearsContextBeforeDrawing = false
        listItemLabel.text = inoutText + " " + postList[indexPath.row].date
        listItemLabel.numberOfLines = 0

        cell.contentView.addSubview(listItemLabel)
        listItemLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            listItemLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            listItemLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            listItemLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            listItemLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
        ])
        return cell
    }
    	
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postList.count
    }
    
    @objc private func clockInOutBtnTapped() {
        print("ClockInOut Button Tapped")
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let userRef = ref.child("attendance").child(userID)
        guard let key = userRef.child("ClockInOut").childByAutoId().key else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: Date())
        clockInOut = (clockInOut == "in") ? "out" : "in";
        
        let post = ["date": dateString,
                    "inout": clockInOut]
        let childUpdates = ["attendance/\(userID)/ClockInOut/\(key)": post]
        ref.updateChildValues(childUpdates) { (error, ref) in
            if let error = error {
                print("ClockInOut Failed:", error)
                return
            }
        }
    }
    
    @objc private func logOutTapped() {
        do {
            try FirebaseAuth.Auth.auth().signOut()
            self.performSegue(withIdentifier: "logoutSegue", sender: self)
        } catch {
            print("SignOut Error")
        }
    }

    
    @objc private func updateButtonUI() {
        if clockInOut == "in" {
            button.setTitle("퇴근하기", for: .normal)
        }
        else {
            button.setTitle("출근하기", for: .normal)
        }
    }
    
    @objc private func tick() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: Date())
        label.text = dateString
    }
}

class Post {
    var date : String
    var inOut : String
    
    init(date: String, inOut: String) {
        self.date = date
        self.inOut = inOut
    }
}
