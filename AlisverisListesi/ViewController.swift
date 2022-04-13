//
//  ViewController.swift
//  AlisverisListesi
//
//  Created by MacBook on 12.04.2022.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    var secilenIsim = ""
    var secilenUUID : UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.edit, target: self, action: #selector(editButtonTapped))
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(ekleButtonTapped))
        
        verileriAl()
    }
    override func viewWillAppear(_ animated: Bool) {
        //gözlemci eklendi
        NotificationCenter.default.addObserver(self, selector: #selector(verileriAl), name: NSNotification.Name(rawValue: "veriGirildi"), object: nil)
    }
    
    @objc func editButtonTapped() {
        print("Edit Button will tapped")
    }
    
    
    @objc func verileriAl(){
        
        isimDizisi.removeAll(keepingCapacity: false)
        idDizisi.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        //data'dan verileri alırken NSFetchRequest formatında isteniyor.
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alisveris")
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let sonuclar = try context.fetch(fetchRequest) //burda bi dizi oluşturuldu
            //CoreData'dan geldiği için veriler, bunlar NSManagedObject içine koyulabilir
            if sonuclar.count > 0 {
                for sonuc in sonuclar as! [NSManagedObject]{
                    //any döndürüyor NSManagedObject, biz de burda NSManagedObject içindeki verinin String olabilirliğini değerlendiriyoruz. Any olan işlemlerde böyle yap. Burda optinal bir sonuç geliyor ama sonuçta çevrile de bilir çevrilmeye de bilir.

                    if let isim = sonuc.value(forKey: "isim") as? String {
                        isimDizisi.append(isim)
                    }
                    
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        idDizisi.append(id)
                    }
                }
                
                tableView.reloadData()
            }
            
        } catch {
            print("Hata var")
        }
    }
    
    
    @objc func ekleButtonTapped(){
        //ekleme butonuna bastığımda secilen ismi bos olarak belirtiyorum ve ekleme butonuna basılarak geldiğinden emin oluyorum. Diğer viewController yani detailsVC de bundan haberdar olmuş oluyor.
        secilenIsim = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        secilenIsim = isimDizisi[indexPath.row]
        secilenUUID = idDizisi[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsViewController
            destinationVC.secilenUrunIsmi = secilenIsim
            destinationVC.secilenUrunUUID = secilenUUID
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alisveris")
            let uuidString = idDizisi[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let sonuclar = try context.fetch(fetchRequest)
                if sonuclar.count > 0 {
                    for sonuc in sonuclar as! [NSManagedObject] {
                        if let id = sonuc.value(forKey: "id") as? UUID {
                            //veriyi sileceğimiz için artık son bir kontrol mekanizması ekledik yanlış veriyi silmemek için
                            if id == idDizisi[indexPath.row] {
                                context.delete(sonuc)
                                isimDizisi.remove(at: indexPath.row)
                                idDizisi.remove(at: indexPath.row)
                                self.tableView.reloadData() //en dıştaki tableView'e erişim sağlar, normal bir şekilde çağırsaydık da aynısı olacaktı fakat böyle yaparak emin olmayı sağladık
                                do {
                                    try context.save()
                                } catch {
                                    print("Hata")
                                }
                                break //id'yi bulup sildiysek daha da döngüyü devam ettirmenin bi anlamıyok
                            }
                        }
                    }
                }
            } catch {
                print("Hata")
            }
            
            
        }
    }
    
    
}
