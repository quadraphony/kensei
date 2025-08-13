package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
	"unsafe"

	"github.com/sagernet/sing-box"
	"github.com/sagernet/sing-box/option"
)

// VPN instance management
var vpnInstance *box.Box
var vpnContext context.Context
var vpnCancel context.CancelFunc

// VMess configuration structure
type VMess struct {
	Add  string `json:"add"`
	Aid  string `json:"aid"`
	Alpn string `json:"alpn"`
	Fp   string `json:"fp"`
	Host string `json:"host"`
	ID   string `json:"id"`
	Net  string `json:"net"`
	Path string `json:"path"`
	Port string `json:"port"`
	PS   string `json:"ps"`
	Scy  string `json:"scy"`
	Sni  string `json:"sni"`
	TLS  string `json:"tls"`
	Type string `json:"type"`
	V    string `json:"v"`
}

// Trojan configuration structure
type Trojan struct {
	Password string `json:"password"`
	Server   string `json:"server"`
	Port     int    `json:"port"`
	SNI      string `json:"sni"`
	Type     string `json:"type"`
	Host     string `json:"host"`
	Path     string `json:"path"`
}

// VLESS configuration structure
type VLESS struct {
	ID         string `json:"id"`
	Server     string `json:"server"`
	Port       int    `json:"port"`
	Encryption string `json:"encryption"`
	Security   string `json:"security"`
	Type       string `json:"type"`
	Host       string `json:"host"`
	Path       string `json:"path"`
	SNI        string `json:"sni"`
}

// Shadowsocks configuration structure
type Shadowsocks struct {
	Server     string `json:"server"`
	ServerPort int    `json:"server_port"`
	Method     string `json:"method"`
	Password   string `json:"password"`
	Plugin     string `json:"plugin,omitempty"`
	PluginOpts string `json:"plugin_opts,omitempty"`
}

// WireGuard configuration structure
type WireGuard struct {
	Server        string   `json:"server"`
	ServerPort    int      `json:"server_port"`
	PrivateKey    string   `json:"private_key"`
	PeerPublicKey string   `json:"peer_public_key"`
	LocalAddress  []string `json:"local_address"`
	MTU           int      `json:"mtu,omitempty"`
}

// TUIC configuration structure
type TUIC struct {
	Server     string `json:"server"`
	ServerPort int    `json:"server_port"`
	UUID       string `json:"uuid"`
	Password   string `json:"password"`
	ALPN       string `json:"alpn,omitempty"`
	SNI        string `json:"sni,omitempty"`
}

// Hysteria configuration structure
type Hysteria struct {
	Server     string `json:"server"`
	ServerPort int    `json:"server_port"`
	Auth       string `json:"auth"`
	ALPN       string `json:"alpn,omitempty"`
	SNI        string `json:"sni,omitempty"`
	Obfs       string `json:"obfs,omitempty"`
}

//export StartVPN
func StartVPN(configJSON *C.char) *C.char {
	config := C.GoString(configJSON)
	
	var options option.Options
	if err := json.Unmarshal([]byte(config), &options); err != nil {
		return C.CString(fmt.Sprintf("Error parsing config: %v", err))
	}

	vpnContext, vpnCancel = context.WithCancel(context.Background())
	
	instance, err := box.New(box.Options{
		Context: vpnContext,
		Options: options,
	})
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating VPN instance: %v", err))
	}

	vpnInstance = instance
	
	go func() {
		if err := vpnInstance.Start(); err != nil {
			fmt.Printf("VPN start error: %v\n", err)
		}
	}()

	return C.CString("VPN started successfully")
}

//export StopVPN
func StopVPN() *C.char {
	if vpnInstance != nil {
		vpnInstance.Close()
		vpnInstance = nil
	}
	if vpnCancel != nil {
		vpnCancel()
		vpnCancel = nil
	}
	return C.CString("VPN stopped successfully")
}

//export GetVPNStatus
func GetVPNStatus() *C.char {
	if vpnInstance == nil {
		return C.CString("disconnected")
	}
	return C.CString("connected")
}

//export FetchSubscription
func FetchSubscription(subscriptionURL *C.char) *C.char {
	url := C.GoString(subscriptionURL)
	
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	
	resp, err := client.Get(url)
	if err != nil {
		return C.CString(fmt.Sprintf("Error fetching subscription: %v", err))
	}
	defer resp.Body.Close()
	
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return C.CString(fmt.Sprintf("Error reading response: %v", err))
	}
	
	// Try to decode as base64 first
	decoded, err := base64.StdEncoding.DecodeString(string(body))
	if err != nil {
		// If not base64, use raw content
		decoded = body
	}
	
	configs := parseSubscriptionContent(string(decoded))
	
	result, err := json.Marshal(configs)
	if err != nil {
		return C.CString(fmt.Sprintf("Error marshaling configs: %v", err))
	}
	
	return C.CString(string(result))
}

func parseSubscriptionContent(content string) []map[string]interface{} {
	var configs []map[string]interface{}
	lines := strings.Split(content, "\n")
	
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		
		if strings.HasPrefix(line, "vmess://") {
			if config := parseVMess(line); config != nil {
				configs = append(configs, config)
			}
		} else if strings.HasPrefix(line, "trojan://") {
			if config := parseTrojan(line); config != nil {
				configs = append(configs, config)
			}
		} else if strings.HasPrefix(line, "vless://") {
			if config := parseVLESS(line); config != nil {
				configs = append(configs, config)
			}
		} else if strings.HasPrefix(line, "ss://") {
			if config := parseShadowsocks(line); config != nil {
				configs = append(configs, config)
			}
		}
	}
	
	return configs
}

func parseVMess(vmessURL string) map[string]interface{} {
	// Remove vmess:// prefix
	encoded := strings.TrimPrefix(vmessURL, "vmess://")
	
	// Decode base64
	decoded, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return nil
	}
	
	var vmess VMess
	if err := json.Unmarshal(decoded, &vmess); err != nil {
		return nil
	}
	
	return map[string]interface{}{
		"type":        "vmess",
		"tag":         vmess.PS,
		"server":      vmess.Add,
		"server_port": vmess.Port,
		"uuid":        vmess.ID,
		"security":    vmess.Scy,
		"alter_id":    vmess.Aid,
		"transport": map[string]interface{}{
			"type": vmess.Net,
			"path": vmess.Path,
			"host": vmess.Host,
		},
		"tls": map[string]interface{}{
			"enabled":     vmess.TLS == "tls",
			"server_name": vmess.Sni,
		},
	}
}

func parseTrojan(trojanURL string) map[string]interface{} {
	u, err := url.Parse(trojanURL)
	if err != nil {
		return nil
	}
	
	password := u.User.Username()
	server := u.Hostname()
	port := u.Port()
	
	query := u.Query()
	sni := query.Get("sni")
	transportType := query.Get("type")
	host := query.Get("host")
	path := query.Get("path")
	
	config := map[string]interface{}{
		"type":        "trojan",
		"tag":         u.Fragment,
		"server":      server,
		"server_port": port,
		"password":    password,
		"tls": map[string]interface{}{
			"enabled":     true,
			"server_name": sni,
		},
	}
	
	if transportType == "ws" {
		config["transport"] = map[string]interface{}{
			"type": "ws",
			"path": path,
			"host": host,
		}
	}
	
	return config
}

func parseVLESS(vlessURL string) map[string]interface{} {
	u, err := url.Parse(vlessURL)
	if err != nil {
		return nil
	}
	
	uuid := u.User.Username()
	server := u.Hostname()
	port := u.Port()
	
	query := u.Query()
	security := query.Get("security")
	transportType := query.Get("type")
	host := query.Get("host")
	path := query.Get("path")
	sni := query.Get("sni")
	
	config := map[string]interface{}{
		"type":        "vless",
		"tag":         u.Fragment,
		"server":      server,
		"server_port": port,
		"uuid":        uuid,
		"flow":        "",
	}
	
	if security == "tls" {
		config["tls"] = map[string]interface{}{
			"enabled":     true,
			"server_name": sni,
		}
	}
	
	if transportType == "ws" {
		config["transport"] = map[string]interface{}{
			"type": "ws",
			"path": path,
			"host": host,
		}
	}
	
	return config
}

func parseShadowsocks(ssURL string) map[string]interface{} {
	u, err := url.Parse(ssURL)
	if err != nil {
		return nil
	}
	
	// Decode user info
	userInfo := u.User.String()
	decoded, err := base64.StdEncoding.DecodeString(userInfo)
	if err != nil {
		return nil
	}
	
	parts := strings.Split(string(decoded), ":")
	if len(parts) != 2 {
		return nil
	}
	
	method := parts[0]
	password := parts[1]
	server := u.Hostname()
	port := u.Port()
	
	return map[string]interface{}{
		"type":        "shadowsocks",
		"tag":         u.Fragment,
		"server":      server,
		"server_port": port,
		"method":      method,
		"password":    password,
	}
}

//export CreateVMessConfig
func CreateVMessConfig(server, port, uuid, security, alterID, network, path, host, tls, sni, tag *C.char) *C.char {
	config := map[string]interface{}{
		"type":        "vmess",
		"tag":         C.GoString(tag),
		"server":      C.GoString(server),
		"server_port": C.GoString(port),
		"uuid":        C.GoString(uuid),
		"security":    C.GoString(security),
		"alter_id":    C.GoString(alterID),
		"transport": map[string]interface{}{
			"type": C.GoString(network),
			"path": C.GoString(path),
			"host": C.GoString(host),
		},
		"tls": map[string]interface{}{
			"enabled":     C.GoString(tls) == "tls",
			"server_name": C.GoString(sni),
		},
	}
	
	result, err := json.Marshal(config)
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating VMess config: %v", err))
	}
	
	return C.CString(string(result))
}

//export CreateTrojanConfig
func CreateTrojanConfig(server, port, password, sni, network, path, host, tag *C.char) *C.char {
	config := map[string]interface{}{
		"type":        "trojan",
		"tag":         C.GoString(tag),
		"server":      C.GoString(server),
		"server_port": C.GoString(port),
		"password":    C.GoString(password),
		"tls": map[string]interface{}{
			"enabled":     true,
			"server_name": C.GoString(sni),
		},
	}
	
	if C.GoString(network) == "ws" {
		config["transport"] = map[string]interface{}{
			"type": "ws",
			"path": C.GoString(path),
			"host": C.GoString(host),
		}
	}
	
	result, err := json.Marshal(config)
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating Trojan config: %v", err))
	}
	
	return C.CString(string(result))
}

//export CreateVLESSConfig
func CreateVLESSConfig(server, port, uuid, flow, security, sni, network, path, host, tag *C.char) *C.char {
	config := map[string]interface{}{
		"type":        "vless",
		"tag":         C.GoString(tag),
		"server":      C.GoString(server),
		"server_port": C.GoString(port),
		"uuid":        C.GoString(uuid),
		"flow":        C.GoString(flow),
	}
	
	if C.GoString(security) == "tls" {
		config["tls"] = map[string]interface{}{
			"enabled":     true,
			"server_name": C.GoString(sni),
		}
	}
	
	if C.GoString(network) == "ws" {
		config["transport"] = map[string]interface{}{
			"type": "ws",
			"path": C.GoString(path),
			"host": C.GoString(host),
		}
	}
	
	result, err := json.Marshal(config)
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating VLESS config: %v", err))
	}
	
	return C.CString(string(result))
}

//export CreateShadowsocksConfig
func CreateShadowsocksConfig(server, port, method, password, tag *C.char) *C.char {
	config := map[string]interface{}{
		"type":        "shadowsocks",
		"tag":         C.GoString(tag),
		"server":      C.GoString(server),
		"server_port": C.GoString(port),
		"method":      C.GoString(method),
		"password":    C.GoString(password),
	}
	
	result, err := json.Marshal(config)
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating Shadowsocks config: %v", err))
	}
	
	return C.CString(string(result))
}

//export CreateWireGuardConfig
func CreateWireGuardConfig(server, port, privateKey, peerPublicKey, localAddress, tag *C.char) *C.char {
	config := map[string]interface{}{
		"type":            "wireguard",
		"tag":             C.GoString(tag),
		"server":          C.GoString(server),
		"server_port":     C.GoString(port),
		"private_key":     C.GoString(privateKey),
		"peer_public_key": C.GoString(peerPublicKey),
		"local_address":   []string{C.GoString(localAddress)},
	}
	
	result, err := json.Marshal(config)
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating WireGuard config: %v", err))
	}
	
	return C.CString(string(result))
}

//export CreateTUICConfig
func CreateTUICConfig(server, port, uuid, password, alpn, sni, tag *C.char) *C.char {
	config := map[string]interface{}{
		"type":        "tuic",
		"tag":         C.GoString(tag),
		"server":      C.GoString(server),
		"server_port": C.GoString(port),
		"uuid":        C.GoString(uuid),
		"password":    C.GoString(password),
		"tls": map[string]interface{}{
			"enabled":     true,
			"server_name": C.GoString(sni),
			"alpn":        []string{C.GoString(alpn)},
		},
	}
	
	result, err := json.Marshal(config)
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating TUIC config: %v", err))
	}
	
	return C.CString(string(result))
}

//export CreateHysteriaConfig
func CreateHysteriaConfig(server, port, auth, alpn, sni, obfs, tag *C.char) *C.char {
	config := map[string]interface{}{
		"type":        "hysteria",
		"tag":         C.GoString(tag),
		"server":      C.GoString(server),
		"server_port": C.GoString(port),
		"auth_str":    C.GoString(auth),
		"tls": map[string]interface{}{
			"enabled":     true,
			"server_name": C.GoString(sni),
			"alpn":        []string{C.GoString(alpn)},
		},
	}
	
	if C.GoString(obfs) != "" {
		config["obfs"] = C.GoString(obfs)
	}
	
	result, err := json.Marshal(config)
	if err != nil {
		return C.CString(fmt.Sprintf("Error creating Hysteria config: %v", err))
	}
	
	return C.CString(string(result))
}

//export FreeString
func FreeString(str *C.char) {
	C.free(unsafe.Pointer(str))
}

func main() {}

