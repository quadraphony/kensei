#ifndef SING_BOX_H
#define SING_BOX_H

#ifdef __cplusplus
extern "C" {
#endif

// VPN control functions
char* StartVPN(char* configJSON);
char* StopVPN();
char* GetVPNStatus();

// Subscription functions
char* FetchSubscription(char* subscriptionURL);

// Configuration creation functions
char* CreateVMessConfig(char* server, char* port, char* uuid, char* security, char* alterID, char* network, char* path, char* host, char* tls, char* sni, char* tag);
char* CreateTrojanConfig(char* server, char* port, char* password, char* sni, char* network, char* path, char* host, char* tag);
char* CreateVLESSConfig(char* server, char* port, char* uuid, char* flow, char* security, char* sni, char* network, char* path, char* host, char* tag);
char* CreateShadowsocksConfig(char* server, char* port, char* method, char* password, char* tag);
char* CreateWireGuardConfig(char* server, char* port, char* privateKey, char* peerPublicKey, char* localAddress, char* tag);
char* CreateTUICConfig(char* server, char* port, char* uuid, char* password, char* alpn, char* sni, char* tag);
char* CreateHysteriaConfig(char* server, char* port, char* auth, char* alpn, char* sni, char* obfs, char* tag);

// Memory management
void FreeString(char* str);

#ifdef __cplusplus
}
#endif

#endif // SING_BOX_H

