//
//  PromptResponseSheet.swift
//  echo
//
//  Created by Max Eisenberg on 9/6/25.
//

import SwiftUI

struct ResponseManager: View {
    
    let promptTitle: String
    let currentFilter: FeedFilter
    let onResponsePosted: () -> Void

    @State var step: ResponseFlowStep = .record
    @State private var responseData = ResponseData()
    @EnvironmentObject var appData: AppData

    var body: some View {
        
        VStack(spacing: 12) {
            
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 20)
                    .fill(.gray)
                    .frame(width: 45, height: 5)
                Spacer()
            }
            .padding(.bottom)
            
     
            HStack(alignment: .top) {
                stepCircle(number: 1, title: "Record", isActive: step == .record)
                    .onTapGesture {
                        step = .record
                    }
                Rectangle()
                    .fill(.gray.opacity(0.30))
                    .frame(height: 1.5)
                    .padding(.horizontal, 8)
                    .offset(y: 10)
                stepCircle(number: 2, title: "Share", isActive: step == .config)
                    .onTapGesture {
                        step = .config
                    }
            }
            .padding(.horizontal, 50)
            
     
            stepContent
        }
        .background(Color(.bgDark).ignoresSafeArea())
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .record:
            RecResponseSheet(
                step: $step,
                promptTitle: promptTitle,
                responseData: $responseData
            )
        case .config:
            ShareConfigs(
                step: $step,
                currentFilter: currentFilter,
                onResponsePosted: onResponsePosted,
                responseData: responseData)
        }
    }
    
    private func stepCircle(number: Int, title: String, isActive: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .strokeBorder(isActive ? .txt : .gray, lineWidth: 1)
                    .frame(width: 20, height: 20)
                
                Text("\(number)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isActive ? .txt : .gray)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isActive ? .txt : .gray)
        }
    }
}

enum ResponseFlowStep {
    case record
    case config
}
