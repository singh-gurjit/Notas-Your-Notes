//
//  FilesScreen.swift
//  Notas
//
//  Created by Gurjit Singh on 11/03/20.
//  Copyright © 2020 Gurjit Singh. All rights reserved.
//

import SwiftUI

struct FilesScreen: View {
    
    var body: some View {
        NavigationView {
            List{
                NavigationLink(destination: DetailScreen()) {
                    Text("Hello there")
                }
            }
            }
        
    }
}

struct FilesScreen_Previews: PreviewProvider {
    static var previews: some View {
        FilesScreen()
    }
}
