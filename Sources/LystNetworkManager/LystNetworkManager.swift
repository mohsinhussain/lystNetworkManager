public class NetworkManager {
    private static var sharedInstance : NetworkManager{
        return NetworkManager()
    }

    public class func shared() -> NetworkManager {
        return sharedInstance
    }
}
