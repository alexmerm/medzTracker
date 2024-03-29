//
//  DetailsView.swift
//  medzTracker
//
//  Created by Alex Kaish on 4/6/22.
//

import SwiftUI

struct DetailsView: View {
    var viewModel : MedicineTracker
    @StateObject var medication :Medication //could in theory just pass in an ID, but not bc this is simpler for testing purposes
    @State var isOnLogView : Bool = false
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
                //Dosage Amount
                if let readableDosage = medication.readableDosage {
                    Text("**Dosage** : \(readableDosage)").font(.subheadline)
                    
                }
                Divider()
                //Schedule
                
                if medication.schedule.isScheduled() {
                    if let nextDosageTime = medication.getNextDosageTime(), let timeUntilNextDosageFullString = medication.timeUntilNextDosageFullString {
                        Section {
                            
                            Text("Next Dosage").font(.title2)
    //                        Text("Due in \(timeUntilNextDosageFullString)")
                            Group {
                                Text(timeUntilNextDosageFullString)
                                Text("(\(nextDosageTime.relativeFormattedString))").font(.caption).padding(.leading, 2.0)
                                    
                                    
                            }.padding(.leading)
                        }
                    }
                    
                    Divider()
                    Section {
                        Text("Schedule").font(.title2)
                        Text(medication.schedule.readableSchedule!).padding(.leading)
                    }
                    

                    Divider()
                    
                    
                }
                
                //MARK: Statistics
                
                Section {
                    Text("Statistics").font(.title2)
                    //TODO: Note this currently is only going to show for medications that are specifictime
                    if !medication.schedule.isSpecificTime() {
                        Text("Statistics aren't available for this kind of medication yet").padding(.leading)
                    }
                    else if medication.pastDoses.isEmpty {
                        Text("You haven't taken this yet, so we don't have any statistics").padding(.leading)
                    } else {
                        Text("**Average time taken**: \(medication.avgTimeTakenString)")
                        Text("This is on average  \(medication.timeFromScheduledDoseString ?? "")").padding(.leading)
                    }
                    Divider()
                }
                

                Section {
                    Text("Previous Doses").font(.title2)
                    if medication.pastDoses.isEmpty {
                        Text("You haven't taken this yet").padding(.leading)
                    } else {
                        Group {
                            Divider()
                            ForEach(medication.pastDoses.reversed().prefix(10), id: \.self) { dosage in
                                Text("\(dosage.relativeTimeString)").font(.body)
                                Divider()
                            }
                        }
                        .padding(.leading)
                        
                    }
                }.onAppear {
                    print("numDoses: \(medication.pastDoses.count)")
                }


                
                Spacer()
            }.padding()
                .navigationBarTitle(medication.name)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination:
                                        LogDosageView(viewModel: viewModel, medication: medication,
                                                      timeTaken: Date(),
                                                      isOnLogView: $isOnLogView),
                                       isActive: $isOnLogView,
                                       label: {
                            Label("Log", systemImage: "circle")
                        })
                    }
            })
        }
    }
    
    
}

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let tracker = MedicineTracker()
        tracker.insertDummyData()
        return Group{
            ForEach(tracker.meds.prefix(10)) { med in
                NavigationView {
                    DetailsView(viewModel: tracker, medication: med)
                }
                
            }
        }
    }
}
