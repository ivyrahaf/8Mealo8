//
//  PromisepageViewModel.swift
//  Mealo8
//
//  Created by Rahaf on 11/06/2026.
//

import SwiftUI

// MARK: - PAGE 3: Promise View
struct PromiseView: View {
   var onDone: () -> Void
   @State private var isPromised: Bool = false
   
   var body: some View {
       ZStack {
           Color("background").ignoresSafeArea()
           
           VStack(spacing: 0) {
               Spacer()
               
               VStack(spacing: 8) {
                   Text("As you know, consistency takes effort")
                       .font(.custom("Georgia", size: 18))
                       .foregroundColor(Color("brown").opacity(0.8))
                   
                   HStack(spacing: 4) {
                       Text("Will you stay on track with your")
                           .font(.custom("Georgia", size: 18))
                           .fontWeight(.bold)
                           .foregroundColor(.black.opacity(0.8))
                       Text("meals?")
                           .font(.custom("Georgia", size: 18))
                           .fontWeight(.bold)
                           .foregroundColor(Color("orange"))
                   }
               }
               
               Spacer().frame(height: 40)
               
               Text("Promise yourself to complete your meals by signing below:")
                   .font(.system(size: 13))
                   .foregroundColor(Color("orange").opacity(0.6))
                   .padding(.bottom, 16)
               
               ZStack {
                   Image("p")
                       .resizable()
                       .scaledToFit()
                       .frame(height: 200)
                   
                   if isPromised {
                       Image("pp")
                           .resizable()
                           .scaledToFit()
                           .frame(width: 200, height: 200)
                           .transition(.scale(scale: 0.5).combined(with: .opacity))
                   }
               }
               .frame(width: 300, height: 300)
               
               Spacer()
               
               Button(action: {
                   withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                       isPromised = true
                   }
                   DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                       onDone()
                   }
               }) {
                   Text(isPromised ? "Promised! ✨" : "I Promise Myself")
                       .font(.system(size: 15, weight: .medium))
                       .foregroundColor(.white)
                       .frame(maxWidth: .infinity)
                       .padding(.vertical, 16)
                       .background(Color("orange"))
                       .clipShape(Capsule())
                       .shadow(color: Color("orange").opacity(0.3), radius: 10, x: 0, y: 4)
               }
               .padding(.horizontal, 24)
               .padding(.bottom, 100)
               .disabled(isPromised)
               
               Image("Point3")
                   .frame(maxWidth: .infinity, alignment: .center)
                   .padding(.bottom, 32)
           }
       }
       .navigationBarBackButtonHidden(true)
   }
}

#Preview {
   PromiseView(onDone: {})
}
