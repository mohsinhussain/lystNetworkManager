//
//  File.swift
//  
//
//  Created by Mohsin Hussain on 07/08/2021.
//

import Foundation
import LystModels

public enum AppEnvironment: String {
    case Release
    case Staging
    case Debug
}

public class LystNetworkManagerSettings {

    public static let shared = LystNetworkManagerSettings()

    private class Config {
        var environment: AppEnvironment?
        var region: Region?
    }

    private static let config = Config()
    public var environment: AppEnvironment
    var region: Region

    fileprivate var environmentsDict: NSDictionary!
    fileprivate let configurationKey = "Configuration"
    fileprivate let environmentPlistName = "EnvironmentVariables"
    fileprivate var activeEnviromentDictionary: NSDictionary!

    public class func setup(environment: AppEnvironment, region: Region,dbVersion: Int) {
        LystNetworkManagerSettings.config.environment = environment
        LystNetworkManagerSettings.config.region = region

        shared.initAPIConfig()
    }

    private init() {
        guard
              let environment = LystNetworkManagerSettings.config.environment,
              let region = LystNetworkManagerSettings.config.region

        else {
            fatalError("Error - you must call setup before accessing MySingleton.shared")
        }
        self.environment = environment
        self.region = region
        initAPIConfig()
    }

    fileprivate func initAPIConfig() {
        let bundle = Bundle.module

        // load our configuration plist
        if let environmentPath = bundle.path(forResource: environmentPlistName, ofType: "plist") {
            environmentsDict = NSDictionary(contentsOfFile: environmentPath)
        }

        if let envDict = environmentsDict,
           let regionDict = envDict[self.region.rawValue] as? NSDictionary,
           let activeDictionary = (regionDict[self.environment.rawValue] as? NSDictionary) {
            self.activeEnviromentDictionary = activeDictionary
        }
    }

    public enum APIURL: String {
        case apiKey
        case dogURL

        public var stringValue: String {
            let appConfig = try? LystNetworkManagerSettings.shared.setting(self)
            return appConfig ?? ""
        }
    }

    public func URLfor(endPoint: APIURL) -> String {
        let appConfig = try? LystNetworkManagerSettings.shared.setting(endPoint)
        return appConfig ?? ""

    }

    fileprivate func setting(_ property: APIURL) throws -> String {
        if let value = self.activeEnviromentDictionary[property.rawValue] as? String {
            return value
        }
        throw NSError(domain: "No <\(property.rawValue)> setting has been found", code: 100012, userInfo: nil)
    }
}

import class Foundation.Bundle

private class BundleFinder {}
