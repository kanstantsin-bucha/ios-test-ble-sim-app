//
//  ViewController.swift
//  test.ble
//
//  Created by Kanstantsin Bucha on 22/02/2023.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController {
    
    @IBOutlet weak var readResult: UILabel!
    @IBOutlet weak var subscribeResult: UILabel!
    @IBOutlet weak var writeResult: UILabel!
    @IBOutlet weak var connect: UILabel!

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    var readChar: CBCharacteristic?
    var writeChar: CBCharacteristic?
    
    let serviceID = CBUUID(string: "E92BBD6E-67CD-4D1D-8EA7-A09CC03B9B0E")
    let readID = CBUUID(string: "FC0F60D0-C06D-452E-B63A-B6128D13D0C4")
    let writeID = CBUUID(string: "B33FE8E3-45F4-47AD-B1B8-2F7358218497")
    
    @IBAction func read() {
        readChar.map {
            readResult.text = "Reading"
            peripheral.readValue(for: $0)
        }
    }
    
    @IBAction func subscribe() {
        readChar.map {
            subscribeResult.text = "Subscribing"
            peripheral.setNotifyValue(true, for: $0)
        }
    }
    
    
    @IBAction func write() {
        writeChar.map {
            writeResult.text = "Writing"
            peripheral.writeValue(Data(repeating: 1, count: 1), for: $0, type: .withResponse)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
}


extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
            
        case .poweredOn:
            print("central.state is .poweredOn Start Scanning")

            centralManager.scanForPeripherals(withServices: [serviceID])
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("found peripheral: \(peripheral)")
        self.peripheral = peripheral
        peripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        connect.text = "Connected"
        peripheral.discoverServices([serviceID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connect.text = "Failed to connect"
        print("didFailToConnect: \(String(describing: error))")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connect.text = "Disconnected"
        print("Disconnected!")
    }
    
    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
        print("peripheral.ancsAuthorized \(peripheral.ancsAuthorized)")
    }
}

extension ViewController: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(service)
            print(service.characteristics ?? "characteristics are nil")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.uuid == readID {
                readChar = characteristic
            }
            if characteristic.uuid == writeID {
                writeChar = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor: \(characteristic.uuid) \(String(describing: error))")
        subscribeResult.text = error?.localizedDescription ?? "Subscribed"
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("didUpdateValueForCharacteristic: \(characteristic.uuid) \(String(describing: error))")
        if characteristic.uuid == readID {
            readResult.text = error?.localizedDescription ?? "Value: \(String(describing: characteristic.value))"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == writeID {
            writeResult.text = error?.localizedDescription ?? "Done"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("didModifyServices: \(invalidatedServices)")
    }
}


