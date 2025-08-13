Kensei App Feature Proposal

This proposal outlines new features for the Kensei VPN application, focusing on user convenience and expanding functionality based on common features found in competitor VPN apps.

1. Proposed Features

1.1. Paste from Clipboard for Profile Import

Description: Allow users to easily import VPN profiles by pasting configuration strings directly from their device's clipboard. This is a common and highly convenient method for users to add new VPN configurations, especially those shared as text.

Feasibility Analysis:

•
Technical Feasibility: Highly feasible. Flutter provides the Clipboard class (from package:flutter/services) which allows reading text data from the system clipboard. The ProfileService already has addProfile methods for various VPN protocols, and a parsing mechanism (_parseSubscriptionConfig) that could be adapted or extended to handle single profile strings.

•
Implementation Outline:

1.
UI Integration: Add a



button or an option in the 'Add Profile' screen (or a new 'Import Profile' screen) that triggers the paste action.
2.  Clipboard Reading: Use Clipboard.getData(Clipboard.kTextPlain) to retrieve the text from the clipboard.
3.  Parsing Logic: Develop a robust parsing function that can interpret various VPN configuration formats (e.g., vmess://, ss://, trojan:// URLs, or raw JSON/text configurations) from the pasted string. This might involve extending the existing _parseSubscriptionConfig or creating a new dedicated parser.
4.  Profile Creation: Once parsed, use the existing ProfileService.addProfile methods to create and save the new VPN profile.
5.  Error Handling: Provide clear feedback to the user if the pasted content is not a valid VPN configuration.

1.2. Share Profile

Description: Enable users to share their custom-created or imported VPN profiles with others. This could be implemented by generating a shareable link (e.g., a QR code or a text string) that encapsulates the profile's configuration.

Feasibility Analysis:

•
Technical Feasibility: Highly feasible. Flutter's share_plus package provides a straightforward way to integrate with the platform's native sharing UI. Generating a shareable string or QR code from a VPNConfig object is also achievable.

•
Implementation Outline:

1.
UI Integration: Add a 'Share' button or option within the profile details view or the profiles list.

2.
Profile Serialization: Convert the VPNConfig object into a shareable string format. This could be a base64 encoded JSON string of the VPNConfig or a standardized VPN URI scheme (e.g., vmess://, ss://).

3.
QR Code Generation (Optional but Recommended): For easier sharing, especially for complex configurations, generate a QR code from the serialized profile string. Flutter packages like qr_flutter can be used for this.

4.
Sharing Intent: Use Share.share() from share_plus to invoke the native sharing sheet, allowing users to share the string or QR code image via various apps (messaging, email, etc.).

5.
Security Consideration: Emphasize to users that sharing profiles involves sharing sensitive connection details and should only be done with trusted individuals.



2. Other Potential Features and Improvements (Based on Competitor Analysis and General Best Practices)

2.1. Kill Switch

Description: Automatically block all internet traffic if the VPN connection drops unexpectedly. This is a critical security feature in many commercial VPN applications.

Feasibility Analysis:

•
Technical Feasibility: Feasible, but requires native platform integration. The sing_box library likely provides APIs for this, or it would involve platform-specific networking APIs (e.g., Android's VpnService, iOS's NetworkExtension).

•
Implementation Outline: Integrate with singBoxBindings or platform-specific APIs to monitor the VPN connection status and modify network rules if the connection is lost.

2.2. Always-on VPN

Description: Ensure the VPN connection is always active, automatically reconnecting if it disconnects and preventing traffic from bypassing the VPN.

Feasibility Analysis:

•
Technical Feasibility: Similar to Kill Switch, this requires native platform capabilities and integration with the sing_box library.

•
Implementation Outline: Configure the underlying VPN service to maintain a persistent connection and automatically re-establish it upon network changes or disconnections.

2.3. Split Tunneling

Description: Allow users to select which applications or websites use the VPN tunnel and which bypass it, providing flexibility and potentially better performance for non-VPN traffic.

Feasibility Analysis:

•
Technical Feasibility: Feasible, but complex. Requires advanced routing capabilities within the VPN client and potentially per-application network control, which is platform-dependent.

•
Implementation Outline: Integrate with sing_box's routing rules or implement custom routing logic based on user-defined application lists.

2.4. Protocol Selection and Customization

Description: Provide more granular control over VPN protocols and their specific settings (e.g., obfuscation methods, specific ports). The current VPNConfig model already supports various protocols, but the UI could expose more options.

Feasibility Analysis:

•
Technical Feasibility: Highly feasible, as the data models already support various protocol configurations.

•
Implementation Outline: Enhance the 'Add Profile' and 'Edit Profile' screens to include advanced settings for each protocol type, allowing users to customize parameters like security, network, path, host, tls, sni, obfs, etc.

2.5. Enhanced Connection Statistics and Logging

Description: Provide more detailed real-time connection statistics (e.g., latency, server load, detailed traffic breakdown) and a more user-friendly log viewer with filtering capabilities.

Feasibility Analysis:

•
Technical Feasibility: Feasible. The VPNService already provides basic ConnectionStats and logStream. Enhancements would involve collecting more metrics from sing_box and improving the UI for display.

•
Implementation Outline: Expand the ConnectionStats model, integrate with sing_box for more detailed metrics, and develop a more sophisticated log viewer with search and filter options.

2.6. Server Latency Test / Speed Test

Description: Allow users to test the latency or speed of different VPN servers to help them choose the fastest available option.

Feasibility Analysis:

•
Technical Feasibility: Feasible. This would involve making network requests to VPN servers and measuring response times or throughput.

•
Implementation Outline: Add a new service for performing speed tests, integrate it with the ProfilesScreen or a new 'Server Test' screen, and display results to the user.

2.7. Dark Mode / Theme Customization

Description: While the app already supports ThemeMode.system, providing explicit dark mode toggles and potentially other theme customization options (e.g., accent colors) can enhance user experience.

Feasibility Analysis:

•
Technical Feasibility: Highly feasible. Flutter's theming system is robust.

•
Implementation Outline: Add theme selection options in the SettingsScreen.

3. Prioritization and Next Steps

Based on user request and feasibility, the immediate next steps would be to focus on:

1.
Paste from Clipboard for Profile Import: This offers significant user convenience and is technically straightforward.

2.
Share Profile: This enhances user collaboration and is also highly feasible.

Other features like Kill Switch and Always-on VPN are critical for a robust VPN client but require deeper native integration and security considerations. Split Tunneling and advanced protocol customization offer power-user features but are more complex to implement. Enhanced statistics and speed tests improve user experience and can be added incrementally.

Recommendation: Proceed with detailed design and implementation of 'Paste from Clipboard' and 'Share Profile' features, followed by a deeper dive into the native integration required for Kill Switch and Always-on VPN.

