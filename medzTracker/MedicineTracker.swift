//
//  MedicineTracker.swift
//  medzTracker
//
//  Created by Alex Kaish on 3/4/22.
//

//THIS IS THE VIEWMODEL
import Foundation

class MedicineTracker : ObservableObject {


    //private(set) means other things can see the model but can't change it
    @Published private(set) var model : MedsDB = MedsDB()
    
    ///These Methods are for intents from the view to modify or access the model

    //Add Medication to model
    func addMedicationToModel(medName : String, dosage : Int?, dosageUnit : String?, schedule : MedsDB.Medication.ScheduleType, maxDosage : Int?, reminders : Bool) -> UUID {
        return model.addMedication(medName: medName, dosage: dosage, dosageUnit: dosageUnit, schedule: schedule, maxDosage: maxDosage, reminders: reminders)
    }
    
    func getMedicationByUUID(_ uuid : UUID)  -> MedsDB.Medication?{
        model.getMedicationByUUID(uuid)
    }
    
    func logDosage(uuid : UUID, time : Date, amount : Int) {
        model.logDosage(uuid, time: time, amount: amount)
    }
    
    var meds: [MedsDB.Medication] {
        return model.medications
    }
    
    
    func insertDummyData() {
        let id1 = self.addMedicationToModel(medName: "Adderall IR", dosage: 10, dosageUnit: "mg", schedule: MedsDB.Medication.ScheduleType.intervalSchedule(interval: TimeInterval(60 * 60 * 4)), maxDosage: 60, reminders: true)

        let id2 = self.addMedicationToModel(medName: "Claratin", dosage: nil, dosageUnit: nil, schedule: MedsDB.Medication.ScheduleType.intervalSchedule(interval: TimeInterval(60 * 60 * 4)), maxDosage: 60, reminders: true)
        self.logDosage(uuid: id2, time: Date() - 400, amount: 10)
        let id3 = self.addMedicationToModel(medName: "Sudafed", dosage: 10, dosageUnit: "mg", schedule: MedsDB.Medication.ScheduleType.intervalSchedule(interval: TimeInterval(60 * 60 * 4)), maxDosage: 60, reminders: true)
        self.logDosage(uuid: id3, time: Date() - 200, amount: 10)
    }
    
}