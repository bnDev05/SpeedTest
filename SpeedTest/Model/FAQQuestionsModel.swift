import SwiftUI

struct FAQQuestionsModel {
    let id = UUID()
    let question: String
    var isTitleText: String? = nil
    let answerStrings: [String]
    let isDotted: Bool
    
    static func fetchQuestions() -> [FAQQuestionsModel] {
        [
            FAQQuestionsModel(question: "How to resolve an internet connection issue?", answerStrings: ["Open the Settings app → Wi-Fi, tap the details of your current Wi-Fi network, and ensure that Configure IP is set to Automatic, Configure DNS is set to Automatic, and Configure Proxy is Off.", "Open the Settings app, turn off Wi-Fi or Cellular Data, wait a few seconds, then turn it back on.", "Open Settings → VPN and disable any active VPN connections.", "Try turning off your device or your router, then restart it.", "Check whether your internet service subscription has expired—you may need to log in again or renew your plan."], isDotted: true),
            FAQQuestionsModel(question: "How to fix a DNS error?", answerStrings: ["Open Settings → Wi-Fi, check the details of your connected Wi-Fi network, and make sure that Configure DNS is set to Automatic and Configure Proxy is set to Off."], isDotted: false),
            FAQQuestionsModel(question: "How to fix a weak signal?" ,answerStrings: ["""
If your Wi-Fi signal is weak or unstable, try the following:
• Turn off and restart your phone or tablet, then reconnect to Wi-Fi.
• If you’re using a home router, turn it off for about 10 seconds, then power it back on.
• If you’re connected to a public Wi-Fi network, try moving to a different location to avoid signal blockage from buildings.
• Attempt to connect to another available and reliable Wi-Fi network.
If your mobile network signal is weak or unstable, we recommend:
• Turning off and restarting your phone or tablet, then reconnecting to the mobile network.
• Changing your location to avoid signal obstruction caused by buildings or large crowds.
• Closing other background apps running on your phone.
"""], isDotted: false),
            FAQQuestionsModel(question: "What do these terms mean?", answerStrings: ["""
DNS:
Domain Name Servers (DNS) are the Internet’s equivalent of a phone book. They maintain a directory of domain names (e.g., www.example.com) and translate them into Internet Protocol (IP) addresses (e.g., 192.0.2.1). This translation is necessary because, while domain names are easy for people to remember, computers and other devices access websites using IP addresses.
Internet Connection:
An internet connection is the ability to link to the Internet using devices such as computers, smartphones, or other terminals, thereby enabling access to online services like email and the World Wide Web.
Server Connection:
The app requests speed-test resources from a server. If the connection between client devices (such as your cellphone) and the server is unstable or fails, the app won’t be able to retrieve the necessary resources, resulting in a failed speed test.
"""], isDotted: false),
            FAQQuestionsModel(question: "What is the purpose of changing the server?", answerStrings: ["""
Since many websites and streaming services host their content on servers located in different regions, speed test results from a single server may be inaccurate (for example, when you're using a VPN to access the internet). To provide the most reliable speed test, the system uses the server closest to your location.
"""], isDotted: false),
            FAQQuestionsModel(question: "Introduction to Ping Test", answerStrings: ["""
Definition:
A ping test is primarily used to check the responsiveness and stability of a connected network.

Principle:
Because every IP address or URL is unique, your device sends a small test data packet to the target IP address or URL and requests that the destination return a packet of the same size. This process determines whether the two devices are successfully connected over the internet and measures the round-trip time—also known as latency or response time—between them.

Packet Loss Rate:
Packet loss rate refers to the percentage of data packets that fail to reach their destination during the test relative to the total number of packets sent. It is a key indicator of network quality. Packet loss is typically influenced by two main factors: the network connection itself and the router.

Latency:
Latency, also called response time, is the duration it takes for a data packet to travel from your device to the target server and back. The shorter the response time, the faster your device communicates with the tested IP address or URL. Generally, latency between 0 and 100 milliseconds (ms) is considered excellent and unlikely to cause noticeable lag or stuttering.
"""], isDotted: false)
        ]
    }
}
