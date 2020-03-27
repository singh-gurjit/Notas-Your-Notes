//
//  ContentView.swift
//  Notas
//
//  Created by Gurjit Singh on 10/03/20.
//  Copyright © 2020 Gurjit Singh. All rights reserved.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    init() {
        //set navigation bar transparent
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        UINavigationBar.appearance().shadowImage = UIImage()
    }
    
    var body: some View {
        NavigationView {
            //display folder view as intial screen
            FoldersView()
        }.accentColor(Color.pink)
    }
}

struct FoldersView: View {
    
    @State var isNewFolderAlertShowing = false
    //create variable for new folder name
    @State private var newFolderName: String = ""
    //create variable to know new folder alert if empty
    @State private var showingEmptyNameAlert = false
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: Folders.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Folders.displayOrder, ascending: false)]) var folders: FetchedResults<Folders>
    
    //fetching record from folder entity
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Folders")
    
    var body: some View {
        
        VStack(alignment: .trailing) {
            List {
                Section(header: Text("New Folder").font(.subheadline).bold()) {
                    HStack {
                        //set textfield for new folder
                        TextField("Name", text: $newFolderName)
                        Button(action: {
                            
                            if (self.newFolderName.isEmpty) {
                                //show alert if new folder textfield is empty
                                self.showingEmptyNameAlert = true
                            } else {
                                //get current date
                                let getDate = getCurrentDate()
                                let formatter = DateFormatter()
                                formatter.dateFormat = "d MMM y"
                                let changedDate = formatter.date(from: getDate)
                                //insert values into database
                                let folderContext = Folders(context: self.moc)
                                folderContext.id = UUID()
                                folderContext.name = "\(self.newFolderName)"
                                folderContext.displayOrder = Int16(self.folders.endIndex)
                                folderContext.date = changedDate
                                try? self.moc.save()
                                self.newFolderName = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill").foregroundColor(Color.pink).imageScale(.large)
                        }.alert(isPresented: $showingEmptyNameAlert) {
                            //display alert view if empty
                            Alert(title: Text("Alert"), message: Text("Please enter new folder name."), dismissButton: .default(Text("OK")))
                        }                    }
                }
                Section(header: Text("Your Folders").font(.subheadline).bold()) {
                    ForEach(folders,id: \.self) { item in
                        NavigationLink(destination: TestingFilesView(item: item.name ?? "Unknown", itemId: String(item.displayOrder))) {
                            HStack {
                                Image(systemName: "folder").foregroundColor(Color.pink).font(.headline)
                                Text(item.name ?? "Unknown").font(.headline)
                                //Text(String(item.displayOrder))
                            }
                        }
                        
                    }
                        //Delete item function
                        .onDelete{ (indexSet) in
                            for offset in indexSet {
                                //delete row from list view
                                let folder = self.folders[offset]
                                self.moc.delete(folder)
                            }
                            try? self.moc.save()
                    }
                }
            }
            .navigationBarItems(trailing: EditButton()).font(.headline)
            .navigationBarTitle("Folders")
            
        }
    }
}

//function to get current date
func getCurrentDate() -> String {
    let today = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM y"
    let date = formatter.string(from: today)
    return date
}

//function to update record
func updateRecord(from: Int,to: Int) {
    let fromSlot = from
    let toSlot = to
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    
    let managedContext = appDelegate.persistentContainer.viewContext
    let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "Folders")
    fetchRequest.predicate = NSPredicate(format: "displayOrder == %@", "\(fromSlot)")
    do {
        let test = try managedContext.fetch(fetchRequest)
        let objectUpdate = test[0] as! NSManagedObject
        objectUpdate.setValue(Int16(toSlot), forKey: "displayOrder")
        //objectUpdate.setValue("Object 1", forKey: "name")
        print("changing postion \(fromSlot) to \(toSlot)")
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
        
    } catch {
        print(error)
    }
    
    fetchRequest.predicate = NSPredicate(format: "displayOrder == %@", "\(toSlot)")
    do {
        let test = try managedContext.fetch(fetchRequest)
        
        let objectUpdate = test[0] as! NSManagedObject
        objectUpdate.setValue(Int16(fromSlot), forKey: "displayOrder")
        //objectUpdate.setValue("Object 2", forKey: "name")
        print("changing postion \(toSlot) to \(fromSlot)")
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
        
    } catch {
        print(error)
    }
}

//Testing FilesScreen
struct TestingFilesView: View {
    var item: String
    var itemId: String
    
    @State var filesTitle = ["Birthday","Carry","Water","Deo"]
    
    @Environment(\.managedObjectContext) var mocFile
    @FetchRequest(entity: FilesRecord.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \FilesRecord.displayOrder, ascending: false)]) var filesRecord : FetchedResults<FilesRecord>
    
    var body: some View {
        VStack(alignment: .trailing) {
            List {
                ForEach(filesRecord.filter { return $0.folderId == stringToInt(input: itemId) },id: \.self) { file in
                    
                    NavigationLink(destination: DetailsView(getFileTitle: file.title ?? "Unknown", folderId: self.itemId, text: file.descrip ?? "Unknown", category: "Edit",fileId: String(file.displayOrder))) {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "doc.plaintext").font(.headline).foregroundColor(Color.pink)
                                Text(file.title ?? "Unknown").font(.headline).foregroundColor(Color.black)
                            }
                            Text(file.descrip ?? "Unknown")
                                .foregroundColor(Color.black)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Text(changeDateToString(adate: file.date!)).foregroundColor(Color.gray).font(.footnote)
                            
                        }
                    }
                }
                .onDelete{ (indexSet) in
                    for indexset in indexSet {
                        let folder = self.filesRecord[indexset]
                        self.mocFile.delete(folder)
                    }
                    try? self.mocFile.save()
                }
                
            }.navigationBarItems(trailing: EditButton()).font(.headline)
                .navigationBarTitle(item)
            
            Button(action: {
                
            }) {
                NavigationLink(destination: DetailsView(getFileTitle: "", folderId: self.itemId, text: "Write your text here...", category: "New", fileId: "")) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 25))
                }.padding(EdgeInsets(top: 10, leading: 15, bottom: 15, trailing: 15))
            }
        }
    }
}

//change date to string
func changeDateToString(adate: Date) -> String {
    let adate =  adate
    //let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM y"
    let result = formatter.string(from: adate)
    return result
}

//function to change value from string to int
func stringToInt(input: String) -> Int {
    let getInput = Int(input) ?? 1
    return getInput
}

//Details Screen View
struct DetailsView: View {
    
    @State var getFileTitle = ""
    var folderId : String
    @State var text: String
    @State var category: String
    @State var fileId: String
    @State var showingMenuItem = false
    @State var isSaveAlertShowing = false
    @State var showHideMenuButton = false
    @State var showHideSaveButton = true
    
    @Environment(\.managedObjectContext) var mocDetail
    @FetchRequest(entity: FilesRecord.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \FilesRecord.displayOrder, ascending: false)]) var filesDetail : FetchedResults<FilesRecord>
    
    var body: some View {
        
        VStack {
            //set textfield for title
            TextField("Title", text: $getFileTitle).font(.title).padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
            Spacer()
            TextViewTypedTesting(text: $text, stateMenuBtn: $showHideMenuButton, stateSaveBtn: $showHideSaveButton)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                
                .navigationBarItems(trailing:
                    HStack {
                        //check condition to show menu button
                        if showHideMenuButton {
                            Button(action: {
                                self.showingMenuItem.toggle()
                                if self.text == "Write your text here..." {
                                    self.text = ""
                                }
                            }) {
                                
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 22))
                                
                            }.actionSheet(isPresented: $showingMenuItem) {
                                ActionSheet(title: Text(""), message: Text("Choose Option"), buttons: [
                                    .default(Text("Share")) {  },
                                    .default(Text("Delete")) {
                                        deleteDetailData(aDisplayOrder: self.fileId)
                                    },
                                    .cancel()
                                ])
                            }
                            
                        } else {
                            Button(action: {
                                if (self.getFileTitle.isEmpty) || (self.text.isEmpty) || (self.text.contains("Write your text here...")) {
                                    //print("Not Saving\(self.text)")
                                } else {
                                    self.isSaveAlertShowing.toggle()
                                }
                                
                            }) {
                                
                                Text("Save").font(.headline)
                                
                            }.alert(isPresented: $isSaveAlertShowing) {
                                Alert(title: Text("Save"), message: Text("Are you sure you want to save this?"), primaryButton: .destructive(Text("Save")) {
                                    //saving data
                                    let getDate = getCurrentDate()
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "d MMM y"
                                    let changedDate = formatter.date(from: getDate)
                                    let fileContext = FilesRecord(context: self.mocDetail)
                                    //check if its new or edit
                                    if (self.fileId.isEmpty) {
                                        fileContext.id = UUID()
                                        fileContext.title = self.getFileTitle
                                        fileContext.descrip = self.text
                                        fileContext.displayOrder = Int16(self.filesDetail.endIndex)
                                        fileContext.date = changedDate
                                        print("Folder Id: \(self.folderId)")
                                        fileContext.folderId = Int16(self.folderId) ?? 1
                                        try? self.mocDetail.save()
                                    } else {
                                        updateDetailData(aTitle: self.getFileTitle, aDesc: self.text, aDate: changedDate!, aDisplayOrder: self.fileId)
                                    }
                                    
                                    //Should uncomment in next version
                                    //self.showHideMenuButton.toggle()
                                    self.showHideSaveButton.toggle()
                                    }, secondaryButton: .cancel())
                            }
                        }
                    }
            )
                
                .navigationBarTitle("",displayMode: .inline)
            
        }
    }
}

//update data from editing view
func updateDetailData(aTitle: String, aDesc: String, aDate:Date, aDisplayOrder: String) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    let managedContext = appDelegate.persistentContainer.viewContext
    
    let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "FilesRecord")
    fetchRequest.predicate = NSPredicate(format: "displayOrder = %@", "\(aDisplayOrder)")
    do {
        let test = try managedContext.fetch(fetchRequest)
        let objectUpdate = test[0] as! NSManagedObject
        objectUpdate.setValue(aTitle, forKey: "title")
        objectUpdate.setValue(aDesc, forKey: "descrip")
        objectUpdate.setValue(aDate, forKey: "date")
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
    } catch {
        print(error)
    }
}

//delete data from editing view
func deleteDetailData(aDisplayOrder: String) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    let managedContext = appDelegate.persistentContainer.viewContext
    
    let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "FilesRecord")
    fetchRequest.predicate = NSPredicate(format: "displayOrder = %@", "\(aDisplayOrder)")
    do {
        let test = try managedContext.fetch(fetchRequest)
        let objectToDelete = test[0] as! NSManagedObject
        managedContext.delete(objectToDelete)
        do {
            try managedContext.save()
        } catch {
            print(error)
        }
    } catch {
        print(error)
    }
}

func customApperance() {
    let navBarAppearance = UINavigationBarAppearance()
    // Will remove the shadow and set background back to clear
    navBarAppearance.configureWithTransparentBackground()
    
    navBarAppearance.configureWithOpaqueBackground()
    
    navBarAppearance.configureWithDefaultBackground()
}

//custom textfield code
struct TextViewTypedTesting: UIViewRepresentable {
    @Binding var text: String
    @Binding var stateMenuBtn: Bool
    @Binding var stateSaveBtn: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, self, self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        
        let myTextView = UITextView()
        myTextView.delegate = context.coordinator
        myTextView.textColor = UIColor.lightGray
        myTextView.font = UIFont(name: "HelveticaNeue", size: 18)
        myTextView.isScrollEnabled = true
        myTextView.isEditable = true
        myTextView.isUserInteractionEnabled = true
        myTextView.backgroundColor = UIColor(white: 0.0, alpha: 0.00)
        
        return myTextView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    class Coordinator : NSObject, UITextViewDelegate {
        
        var parent: TextViewTypedTesting
        
        init(_ uiTextView: TextViewTypedTesting, _ stateMenu: TextViewTypedTesting, _ stateSave: TextViewTypedTesting) {
            self.parent = uiTextView
            self.parent = stateMenu
            self.parent = stateSave
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            return true
        }
        
        func textViewDidChange(_ textView: UITextView) {
            //print("text now: \(String(describing: textView.text!))")
            self.parent.text = textView.text
            
            self.parent.stateMenuBtn = false
            self.parent.stateSaveBtn = true
            
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == UIColor.lightGray {
                if textView.text.contains("Write your text here...") {
                    textView.text = nil
                }
                textView.textColor = UIColor.black
            }
            
            if(textView.text == "Write your text here...") {
                textView.text = nil
                print("empty string matched")
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = "Write your text here..."
                textView.textColor = UIColor.lightGray
                print("empty data")
            }
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

