

import Foundation
import Alamofire
import SwiftyJSON

enum OAuthGrantType: String {
    case Code = "authorization_code"
    case ClientCredentials = "client_credentials"
    case PasswordCredentials = "password"
    case Refresh = "refresh_token"
}


let kOAuth2CredentialServiceName = "OAuthCredentialService"

/**
 `OAuthCredential` models the credentials returned from an OAuth server, storing the token type, access & refresh tokens, and whether the token is expired.
 
 OAuth credentials can be stored in the user's keychain, and retrieved on subsequent launches.
 */
class OAuthCredential: NSObject, NSCoding {
    
    class func keychainQueryDictionaryWithIdentifier(identifier: String) -> NSMutableDictionary {
        return [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : kOAuth2CredentialServiceName,
            kSecAttrAccount as String : identifier
        ]
    }
    
    override var description: String {
        get {
            return "<\(self.dynamicType) accessToken:\"\(self.accessToken)\"\n tokenType:\"\(self.tokenType)\"\n refreshToken:\"\(self.refreshToken)\"\n expiration:\"\(self.expiration)\">"
        }
    }
    
    /**
     The OAuth access token.
     */
    private(set) var accessToken: String!
    
    /**
     The OAuth token type (e.g. "bearer").
     */
    private(set) var tokenType: String!
    
    /**
     The OAuth refresh token.
     */
    var refreshToken: String?
    
    /**
     Whether the OAuth credentials are expired.
     */
    var expired: Bool {
        get {
            return self.expiration?.compare(NSDate()) == .OrderedAscending
        }
    }
    
    /**
     The expiration date of the credential.
     */
    var expiration: NSDate?

    
    /**
     Creates an OAuth credential from a token string, with a specified type.
     
     - Parameter token: The OAuth token string.
     - Parameter type:  The OAuth token type.
     */
    class func credentialWithOAuthToken(
        token token: String,
        tokenType: String
        ) -> OAuthCredential {
        return self.init(token: token, tokenType: tokenType)
    }
    
    /**
     Initializes an OAuth credential from a token string, with a specified type.
     
     - Parameter token: The OAuth token string.
     - Parameter type:  The OAuth token type.
     */
    required init(token: String, tokenType: String) {
        self.accessToken = token
        self.tokenType = tokenType
        super.init()
    }
    
    /**
     Creates an OAuth credential from the specified URL string, username, password and scope. Please note that this method `must` be run on a background thread or else it will cause your application to become completely unresponsive.
     
     - Parameter URLString:                 The URL string used to create the request URL.
     - Parameter username:                  The username used for authentication.
     - Parameter password:                  The password used for authentication.
     - Parameter scope:                     The authorization scope.
     - Parameter clientID:                  Your client ID for the service.
     - Parameter clientSecret:              Your client secret for the service.
     - Parameter useBasicAuthentication:    Whether you want to send your client ID and client secret as parameters or headers. Defaults to true.
     
     - Throws: Error if request fails
     */
    convenience init(
        URLString: String,
        username: String,
        password: String,
        scope: String? = nil,
        clientID: String,
        clientSecret: String,
        useBasicAuthentication: Bool = true
        ) throws {
        var params = ["username": username, "password": password, "grant_type": OAuthGrantType.PasswordCredentials.rawValue]
        if scope != nil {
            params["scope"] = scope!
        }
        try self.init(URLString: URLString, parameters: params, clientID: clientID, clientSecret: clientSecret, useBasicAuthentication: useBasicAuthentication)
    }
    
    /**
     Refreshes the OAuth token for the specified URL string, username, password and scope. Please note that this method `must` be run on a background thread or else it will cause your application to become completely unresponsive.
     
     - Parameter URLString:                 The URL string used to create the request URL.
     - Parameter refreshToken:              The refresh token returned from the authorization code exchange.
     - Parameter clientID:                  Your client ID for the service.
     - Parameter clientSecret:              Your client secret for the service.
     - Parameter useBasicAuthentication:    Whether you want to send your client ID and client secret as parameters or headers. Defaults to true.
     
     - Throws: Error if request fails.
     */
    convenience init(
        URLString: String,
        refreshToken: String,
        clientID: String,
        clientSecret: String,
        useBasicAuthentication: Bool = true
        ) throws {
        let params = ["refresh_token": refreshToken, "grant_type": OAuthGrantType.Refresh.rawValue]
        try self.init(URLString: URLString, parameters: params, clientID: clientID, clientSecret: clientSecret, useBasicAuthentication: useBasicAuthentication)
    }
    
    /**
     Creates an OAuth credential from the specified URL string, code. Please note that this method `must` be run on a background thread or else it will cause your application to become completely unresponsive.
     
     - Parameter URLString:                 The URL string used to create the request URL.
     - Parameter code:                      The authorization code.
     - Parameter redirectURI:               The URI to redirect to after successful authentication.
     - Parameter clientID:                  Your client ID for the service.
     - Parameter clientSecret:              Your client secret for the service.
     - Parameter useBasicAuthentication:    Whether you want to send your client ID and client secret as parameters or headers. Defaults to true.
     
     - Throws: Error if request fails
     */
    convenience init(
        URLString: String,
        code: String,
        redirectURI: String,
        clientID: String,
        clientSecret: String,
        useBasicAuthentication: Bool = true
        ) throws {
        let params = ["grant_type": OAuthGrantType.Code.rawValue, "code": code, "redirect_uri": redirectURI]
        try self.init(URLString: URLString, parameters: params, clientID: clientID, clientSecret: clientSecret, useBasicAuthentication: useBasicAuthentication)
    }
    
    /**
     Creates an OAuth credential from the specified parameters. Please note that this method `must` be run on a background thread or else it will cause your application to become completely unresponsive.
     
     - Parameter URLString:                 The URL string used to create the request URL.
     - Parameter parameters:                The parameters to be encoded and set in the request HTTP body.
     - Parameter clientID:                  Your client ID for the service.
     - Parameter clientSecret:              Your client secret for the service.
     - Parameter useBasicAuthentication:    Whether you want to send your client ID and client secret as parameters or headers. Defaults to true.
     
     - Throws: Error if request fails
     */
    init(
        URLString: String,
        parameters: [String: AnyObject],
        clientID: String,
        clientSecret: String,
        useBasicAuthentication: Bool = true
        ) throws {
        assert(!NSThread.isMainThread(), "The function: \(#function) must be run on a background thread.")
        var headers: [String: String]?
        var parameters = parameters
        if useBasicAuthentication {
            headers = ["Authorization": "Basic \("\(clientID):\(clientSecret)".dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.init(rawValue: 0)))"]
        } else {
            parameters["client_id"] = clientID
            parameters["client_secret"] = clientSecret
        }
        let semaphore = dispatch_semaphore_create(0)
        var error: NSError?
        super.init()
        Alamofire.request(.POST, URLString, parameters: parameters, headers: headers).validate().responseJSON { response in
            guard response.result.isSuccess else {
                dispatch_semaphore_signal(semaphore)
                error = response.result.error!
                return
            }
            let responseObject = JSON(response.result.value!)
            var refreshToken = responseObject["refresh_token"].string
            if refreshToken == nil || refreshToken == NSNull() {
                refreshToken = parameters["refresh_token"] as? String
            }
            self.accessToken = responseObject["access_token"].string!
            self.tokenType = responseObject["token_type"].string!
            if refreshToken != nil // refreshToken is optional in the OAuth2 spec.
            {
                self.refreshToken = refreshToken!
            }
            
            // Expiration is optional, but recommended in the OAuth2 spec. It not provide, assume distantFuture === never expires.
            var expireDate: NSDate? = NSDate.distantFuture()
            let expiresIn = responseObject["expires_in"].int
            if expiresIn != nil && expiresIn != NSNull() {
                expireDate = NSDate(timeIntervalSinceNow: Double(expiresIn!))
            }
            if expireDate != nil {
                self.expiration = expireDate!
            }
            dispatch_semaphore_signal(semaphore)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        if error != nil { throw error!}
    }
    
    /**
     Sets the credential refresh token, with a specified expiration.
     
     - Parameter refreshToken:  The OAuth refresh token.
     - Parameter expiration:    The expiration of the access token.
     */
    func setRefreshToken(refreshToken: String, expiration: NSDate) {
        self.refreshToken = refreshToken
        self.expiration = expiration
    }
    
    
    /**
     Stores the specified OAuth credential for a given web service identifier in the Keychain.
     with the default Keychain Accessibilty of kSecAttrAccessibleWhenUnlocked.
     
     - Parameter credential: The OAuth credential to be stored.
     - Parameter identifier: The service identifier associated with the specified credential.
     
     - Returns: Whether or not the credential was stored in the keychain.
     */
    class func storeCredential(credential: OAuthCredential, identifier: String) -> Bool {
        return self.storeCredential(credential, identifier: identifier, accessibility: kSecAttrAccessibleWhenUnlocked)
    }
    
    /**
     Stores the specified OAuth token for a given web service identifier in the Keychain.
     
     - Parameter credential:            The OAuth credential to be stored.
     - Parameter identifier:            The service identifier associated with the specified token.
     - Parameter securityAccessibility: The Keychain security accessibility to store the credential with.
     
     - Returns: Whether or not the credential was stored in the keychain.
     */
    class func storeCredential(
        credential: OAuthCredential,
        identifier: String,
        accessibility: AnyObject
        ) -> Bool {
        let queryDictionary = keychainQueryDictionaryWithIdentifier(identifier)
        
        var updateDictionary = [String: AnyObject]()
        
        updateDictionary[kSecValueData as String] = NSKeyedArchiver.archivedDataWithRootObject(credential)
        updateDictionary[kSecAttrAccessible as String] = accessibility
        
        let status: OSStatus
        
        let exists = retrieveCredentialWithIdentifier(identifier) != nil
        
        if exists {
            status = SecItemUpdate(queryDictionary as CFDictionary, updateDictionary);
        } else {
            queryDictionary.addEntriesFromDictionary(updateDictionary)
            status = SecItemAdd(queryDictionary as CFDictionary, nil)
        }
        
        return (status == errSecSuccess)
    }
    
    /**
     Retrieves the OAuth credential stored with the specified service identifier from the Keychain.
     
     - Parameter identifier: The service identifier associated with the specified credential.
     
     - Returns: The retrieved OAuth credential.
     */
    class func retrieveCredentialWithIdentifier(identifier: String) -> OAuthCredential? {
        let queryDictionary = keychainQueryDictionaryWithIdentifier(identifier)
        queryDictionary[kSecReturnData as String] = kCFBooleanTrue
        queryDictionary[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status: OSStatus = withUnsafeMutablePointer(&result) {SecItemCopyMatching(queryDictionary as CFDictionaryRef, UnsafeMutablePointer($0)) }
        
        if status != errSecSuccess {
            return nil
        }
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(result as! NSData) as? OAuthCredential
    }
    
    /**
     Deletes the OAuth credential stored with the specified service identifier from the Keychain.
     
     - Parameter identifier: The service identifier associated with the specified credential.
     
     - Returns: Whether or not the credential was deleted from the keychain.
     */
    class func deleteCredentialWithIdentifier(identifier: String) -> Bool {
        let queryDictionary = keychainQueryDictionaryWithIdentifier(identifier)
        
        let status = SecItemDelete(queryDictionary as CFDictionary)
        
        return (status == errSecSuccess)
    }
    
    // MARK: - NSCoding
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(accessToken, forKey: "accessToken")
        aCoder.encodeObject(tokenType, forKey: "tokenType")
        aCoder.encodeObject(refreshToken, forKey: "refreshToken")
        aCoder.encodeObject(expiration, forKey: "expiration")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        accessToken = aDecoder.decodeObjectForKey("accessToken") as! String
        tokenType = aDecoder.decodeObjectForKey("tokenType") as! String
        refreshToken = aDecoder.decodeObjectForKey("refreshToken") as? String
        expiration = aDecoder.decodeObjectForKey("expiration") as? NSDate
    }
}
