# 📱 FlashDash Deals - Flutter Mobile Application Setup Guide

This guide explains how to connect and run the FlashDash Deals Flutter mobile application against the containerized backend during local development and testing on physical Android devices.

---

## 🔗 Dev Server Connectivity

Because the host machine IP changes depending on the network environment (e.g., college WiFi vs. phone hotspot), the API base URL is **runtime-configurable**.

### Accessing Dev Settings
1. On the **Login** screen, in debug mode, a **settings gear icon** is visible in the top-right corner.
2. Click this icon to open the **Dev Server Settings** screen.
3. Enter the IP address and port of your development laptop.
4. Click **Test Connection** to verify cleartext HTTP communication before saving.
5. Click **Save Settings** to apply the configuration immediately (no app restart required).

---

## 📡 Network Environment Scenarios

### Scenario A: Testing via Mobile Hotspot (Recommended for Physical Devices)
If your laptop and physical testing device (e.g., Motorola phone) need to connect without local router isolation:
1. Turn on the **Mobile Hotspot** on the Android phone.
2. Connect your development laptop to the phone's hotspot WiFi network.
3. Find your laptop's IP address on the hotspot network:
   * **Windows (cmd/powershell)**: Run `ipconfig` and look for the IPv4 Address under the *Wireless LAN adapter Wi-Fi* interface (usually starts with `192.168.43.x` or `172.20.10.x`).
   * **Mac/Linux (terminal)**: Run `ifconfig` or `ip a`.
4. Open the app's **Dev Server Settings**, enter the laptop's IP address (port `8080`), and click **Test Connection**.

### Scenario B: Testing via College/Home WiFi Subnet
If both your laptop and test phone are connected to the same college/home WiFi network:
1. Ensure the WiFi network does not have **AP Isolation (Client Isolation)** enabled (many enterprise/college networks block client-to-client traffic).
2. Find the laptop's local IP on the WiFi interface.
3. Configure the IP in the app's **Dev Server Settings** and test the connection.

### Scenario C: Testing via Android Emulator
1. The default host configuration is pre-filled with `10.0.2.2`.
2. This is the special loopback IP that the Android emulator uses to reach the host machine's `localhost` interface.

---

## 🛠️ Required Backend Modifications for Phone Traffic

To allow requests from physical mobile devices, the gateway and backend microservices must accept network requests from the phone:

1.  **Central API Gateway Ingress (KrakenD)**:
    KrakenD runs inside a Docker container mapped to host port `8080`.
    No CORS adjustments are needed because the mobile client is not a browser sandboxed environment, but `krakend/krakend.json` is already configured to permit all origins:
    ```json
    "security/cors": {
      "allow_origins": ["*"]
    }
    ```
2.  **Cleartext Traffic Security Config**:
    To allow Android to talk to the backend over plain HTTP without HTTPS enforcement (since dev runs on cleartext), we have configured a custom [network_security_config.xml](file:///d:/Bharath-user/RVCE/Semester-2/CNA/Project/Ecommerce_CNA_project/mobile_app/android/app/src/main/res/xml/network_security_config.xml) permitting cleartext traffic for local private IP subnets (`192.168.0.x`, `192.168.1.x`, `192.168.43.x`, `172.20.10.x`, `10.0.0.x`).

---

## 🚀 How to Run Mobile App

```bash
cd mobile_app
flutter pub get
flutter run
```
*(Make sure a physical device is connected via USB debugging or an emulator is running)*
