//
//  Scheduler.swift
//  medzTracker
//
//  Created by Alex Kaish on 4/30/22.
//

import Foundation
import SwiftUI
import UserNotifications

class Scheduler {
    
    ///medID : [NotificationId]
    var notificationIDs : [UUID: [String]] = [:]
    
    ///Load notifications from backend, stores them in notificationIDs, and then scheudle all meds
    func loadExistingNotificationsFromSystemAndScheduleAll(medications : [Medication]) {
        Scheduler.getNotificationsFromSystem(completion: { result in
            switch result {
            case .success(let ids):
                self.notificationIDs = ids
                //After loading into Scheduler class, then schedule all meds
                self.scheduleAllNotifications(medications: medications)
            case .failure(let error):
                print(error.localizedDescription)
            }
            
        })
    }
    
    ///Schedule Notiications for all Medications
    func scheduleAllNotifications(medications : [Medication]) {
        medications.forEach({ medication in
            if medication.schedule.isScheduled() && medication.reminders && medication.getNextDosageTime() != nil {
                let _ = self.updateMedicationNotications(medication: medication)
            }
        })
        print(notificationIDs)
    }
    
    ///Drops prev existing notifications for meds and schedules new ones *if* iit's scheduled and enabled
    func updateMedicationNotications(medication : Medication) -> UUID? {
        guard medication.schedule.isScheduled() && medication.reminders else {
            return nil
        }
        removeMedicationsNotifications(medication: medication)
        //Create new notidications
        return scheduleNotification(medication: medication)
    }
    
    ///Remove all existing Notifications for this medication
    func removeMedicationsNotifications(medication : Medication) {
        //Remove all notifations for med by ID
        if let ids = self.notificationIDs[medication.id] {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            //remove from store too
            self.notificationIDs[medication.id] = []
            print("Notifications for \(medication.name) removed")
        }
    }
    
    
    
    ///Store Notifications in notificationIDs
    private func storeNotification(medicationID: UUID, notificationID: String) {
        //If not there, create the arr
        if notificationIDs[medicationID] == nil {
            notificationIDs[medicationID] = [notificationID]
        } else {
            notificationIDs[medicationID]?.append(notificationID)
        }
    }
    
    ///Get permissions to use notifications
    func getNotificationPermissions() {
        NotificationHandler.shared.requestPermission()
    }
    
    
    ///Loads all pending notifications from system and returns them in useful format
    private static func getNotificationsFromSystem(completion: @escaping (Result<[UUID: [String]],Error>) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler:  { requests in
            var notificationIDs : [UUID: [String]] = [:]
            requests.forEach { req in
                //ThreadIdentifier = Medicationid
                let medID = UUID(uuidString: req.content.threadIdentifier)!
                let notificationID = req.identifier
                if let _ = notificationIDs[medID]{
                    notificationIDs[medID] = [notificationID]
                } else {
                    notificationIDs[medID]?.append(notificationID)
                }
            }
            DispatchQueue.main.async {
                completion(.success(notificationIDs))
            }
        })
    }
    
    
    ///Schedules Notification for med, returns id of notification
    private func scheduleNotification(medication: Medication) -> UUID? {
        precondition(medication.schedule.isScheduled(), "Medication have scheduler of scheudlign type")
        precondition(medication.reminders, "Must have reminders enabled")
        let content = Scheduler.generateNotificationContent(medication: medication)
        guard let trigger = Scheduler.generateTrigger(medication: medication) else {
            return nil
        }
        let uuid = UUID() //Notification UUID
        let request = UNNotificationRequest(identifier: uuid.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        print("Scheduled Notification for \(medication.name)")
        //Append to notificationIDS
        self.storeNotification(medicationID: medication.id, notificationID: uuid.uuidString)
        return uuid
    }
    
    ///Generates Notification Content for Medication
    static private func generateNotificationContent(medication : Medication) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(medication.name) Reminder"
        content.subtitle = "It's time to take your \(medication.name)!"
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive
        content.targetContentIdentifier = medication.id.uuidString
        content.threadIdentifier = medication.id.uuidString
        return content
    }
    
    ///Generates Trigger for medication
    ///Returns nil if medication does not have a nextDosageTime
    static private func generateTrigger(medication: Medication) -> UNNotificationTrigger? {
        //only run this on notifications with scheduled
        precondition(medication.schedule.isScheduled())
        //for intervals
        if case Medication.Schedule.intervalSchedule(interval: _) = medication.schedule {
            //Always Log as Date, bc it shouldn't trigger if u didn't take prev one
            //logged over an hr ago , Generate Inteval as Calendar
            if let triggerTime = medication.getNextDosageTime() {
                return UNCalendarNotificationTrigger(dateMatching: triggerTime.asDateComponents, repeats: false)
            } else {
                return nil
            }
        } else if case Medication.Schedule.specificTime(hour: let hour, minute: let minute) = medication.schedule {
            return UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        }
        return nil
    }
    
}
