//
//  DetailsViewController.swift
//  AlisverisListesi
//
//  Created by MacBook on 12.04.2022.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var kaydetButton: UIButton!
    @IBOutlet weak var bedenTextField: UITextField!
    @IBOutlet weak var fiyatTextField: UITextField!
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    var secilenUrunIsmi = ""
    var secilenUrunUUID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if secilenUrunIsmi != "" {
            //CoreData'dan secilen urunbilgilerini göster
            
            kaydetButton.isHidden = true //button gizlendi
            
            if let uuidString = secilenUrunUUID?.uuidString {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                //veri alma işlemi için fetchrequest yap
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alisveris")
                //"id = %@" satırı demektir ki id = uuidString'e eşit olanları getir
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)//args: CVarArgs olan seçilmeli
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            if let isim = sonuc.value(forKey: "isim") as? String {
                                isimTextField.text = isim
                            }
                            if let fiyat = sonuc.value(forKey: "fiyat") as? Int {
                                fiyatTextField.text = String(fiyat)
                            }
                            
                            if let beden = sonuc.value(forKey: "beden") as? String {
                                bedenTextField.text = beden
                            }
                            
                            if let gorselData = sonuc.value(forKey: "gorsel") as? Data {
                                let image = UIImage(data: gorselData)
                                imageView.image = image
                            }
                            
                        }
                    }
                    
                } catch {
                    print("Hata var")
                }
                
                
                
                
                
                print(uuidString)
            }
        } else{
            kaydetButton.isHidden = false
            kaydetButton.isEnabled = false
            isimTextField.text = ""
            fiyatTextField.text = ""
            bedenTextField.text = ""
        }
        
        
        //Dokununca ne yapılacağını burda tanımladık
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeKlavye))
        //nereye dokununca üst satırdaki kod çalışsın diye de aşağıdaki satırı yazdık
        view.addGestureRecognizer(gestureRecognizer)
        
        imageView.isUserInteractionEnabled = true
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(gorselSec))
        imageView.addGestureRecognizer(imageGestureRecognizer)
        
    }
    
    @objc func gorselSec() {
        //burda kullanıcının telefonunun galerisinden fotoğraf alacağız
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
        
        print("Image'e tıklandı")
    }
    
    //gorsel seçtikten sonra işlemi burda yapıyoruz
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        kaydetButton.isEnabled = true
        self.dismiss(animated: true)
    }
    
    
    @objc func closeKlavye(){
        view.endEditing(true)
    }
    
    @IBAction func kaydetTapped(_ sender: UIButton) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate //appDelegate'i ele aldık. İçindeki saveContext fonksiyonuna erişmeye çalışıyoruz
        let context = appDelegate.persistentContainer.viewContext //context tanımladık ve kaydedilecek veriyi tanımladık aslında
        
        let alisveris = NSEntityDescription.insertNewObject(forEntityName: "Alisveris", into: context) //alışverişin context içine gönderilmesini sağlayacağız
        
        alisveris.setValue(isimTextField.text!, forKey: "isim")
        alisveris.setValue(bedenTextField.text!, forKey: "beden")
        if let fiyat = Int(fiyatTextField.text!) { //fiyatın int olup olmadığı kontrolü yapıldı
            alisveris.setValue(fiyat, forKey: "fiyat")
        }
        alisveris.setValue(UUID(), forKey: "id") //Uniq id swift ile oluşturuluyor
        let data = imageView.image!.jpegData(compressionQuality: 0.5) //0.5 oranında datayı sıkıştırarak koyduk
        //yukarı satırda imageview'den gelen veriyi data içine koyduk.Burda image data binary data'ya çevrildi
        
        alisveris.setValue(data, forKey: "gorsel")
        
        do{
            try context.save()
            print("kayit edildi")
        } catch {
            print("Hata oluştu")
        }
        //yeni bir verinin kaydedildiğini ilgili uygulamalara bildirdik
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "veriGirildi"), object: nil)
        self.navigationController?.popViewController(animated: true)
        
    }
}
